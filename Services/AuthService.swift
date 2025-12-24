import Foundation
import FirebaseAuth
import FirebaseFirestore

// Silence all `print` statements in release builds for this file. Declaring a
// local `print` function when `DEBUG` is not set will shadow the global
// `print` implementation, effectively turning debug logs into no-ops in
// production. When compiling with the `DEBUG` flag, this local function is
// not defined and Swift will resolve to the standard library `print`.
#if !DEBUG
private func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var user: UserProfile?
    @Published var isAuthenticated = false
    @Published var isEmailVerified = false

    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    @Published var isCreatingUserProfile = false

    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                self.isAuthenticated = true
                self.isEmailVerified = user.isEmailVerified
                self.fetchUserDocument(uid: user.uid)
            } else {
                self.isAuthenticated = false
                self.isEmailVerified = false
                self.user = nil
                FriendsViewModel.shared.currentUser = nil
                DispatchQueue.main.async {
                    FriendsViewModel.shared.friends = []
                }
            }
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Email Auth
    func signUpWithEmail(
        email: String,
        password: String,
        name: String,
        avatar: String = "", // legacy emoji
        bio: String? = nil,
        phone: String? = nil,
        notificationsEnabled: Bool = true,
        faceIDEnabled: Bool = false,
        avatarSeed: String = "defaultseed",   // DiceBear
        avatarStyle: String = "adventurer",   // DiceBear
        countryCode: String = CurrencyManager.deviceCountryAndCurrencyDefaults().country,
        currencyCode: String = CurrencyManager.deviceCountryAndCurrencyDefaults().currency,
        onProfileCreated: (() -> Void)? = nil
    ) {
        isCreatingUserProfile = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Signup error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                    self.isCreatingUserProfile = false
                }
                return
            }
            guard let firebaseUser = result?.user else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                    self.isCreatingUserProfile = false
                }
                print("Signup: no firebase user returned")
                return
            }
            self.createUserDocument(
                for: firebaseUser,
                name: name,
                avatar: avatar,
                bio: bio,
                phone: phone,
                notificationsEnabled: notificationsEnabled,
                faceIDEnabled: faceIDEnabled,
                avatarSeed: avatarSeed,
                avatarStyle: avatarStyle,
                countryCode: countryCode,
                currencyCode: currencyCode
            ) { created in
                DispatchQueue.main.async {
                    self.isCreatingUserProfile = false
                }
                if created {
                    self.fetchUserDocument(uid: firebaseUser.uid)
                    onProfileCreated?()
                } else {
                    print("Warning: user document creation failed or returned false")
                    self.fetchUserDocument(uid: firebaseUser.uid)
                }
            }
            firebaseUser.sendEmailVerification { error in
                if let error = error {
                    print("Failed to send verification: \(error.localizedDescription)")
                } else {
                    print("Verification email sent!")
                }
            }
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.isEmailVerified = firebaseUser.isEmailVerified
            }
        }
    }

    func signInWithEmail(email: String, password: String, onLoginProgress: ((String?) -> Void)? = nil) {
        if isCreatingUserProfile {
            onLoginProgress?("Account setup in progress, please wait…")
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign in error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                }
                onLoginProgress?(error.localizedDescription)
                return
            }
            guard let firebaseUser = result?.user else {
                print("Sign in: no firebase user returned")
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                }
                onLoginProgress?("No user returned.")
                return
            }
            // ⬇️ Refresh the Firebase user to get the latest emailVerified status
            firebaseUser.reload { [weak self] reloadError in
                guard let self = self else { return }
                if let reloadError = reloadError {
                    print("Failed to reload user: \(reloadError.localizedDescription)")
                }
                // Update authentication flags based on refreshed user
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.isEmailVerified = firebaseUser.isEmailVerified
                }
                // If the email is verified now, update the Firestore user doc to persist this
                if firebaseUser.isEmailVerified {
                    self.db.collection("users").document(firebaseUser.uid).updateData(["emailVerified": true])
                }
                // Fetch user document from Firestore (will propagate into user profile & friends)
                self.tryFetchUserDocumentWithRetry(uid: firebaseUser.uid, attempts: 5, delay: 0.4, onLoginProgress: onLoginProgress)
            }
        }
    }

    private func tryFetchUserDocumentWithRetry(uid: String, attempts: Int, delay: TimeInterval, onLoginProgress: ((String?) -> Void)?) {
        guard attempts > 0 else {
            onLoginProgress?("Account setup in progress. Please try again in a few seconds.")
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
                FriendsViewModel.shared.currentUser = nil
                FriendsViewModel.shared.friends = []
            }
            return
        }
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Firestore fetch error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.user = nil
                    self.isAuthenticated = false
                    FriendsViewModel.shared.currentUser = nil
                    FriendsViewModel.shared.friends = []
                }
                onLoginProgress?(error.localizedDescription)
                return
            }
            guard let data = snapshot?.data() else {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.tryFetchUserDocumentWithRetry(uid: uid, attempts: attempts - 1, delay: delay, onLoginProgress: onLoginProgress)
                }
                return
            }
            let decoded = self.decodeUserProfile(from: data)
            DispatchQueue.main.async {
                self.user = decoded
                self.isAuthenticated = true
                self.isEmailVerified = decoded.emailVerified

                // ⬇️ include avatar fields in minimal user
                let minimal = User(
                    id: decoded.uid,
                    name: decoded.name,
                    email: decoded.email,
                    avatar: decoded.avatar,
                    avatarSeed: decoded.avatarSeed,
                    avatarStyle: decoded.avatarStyle
                )

                FriendsViewModel.shared.currentUser = minimal
                FriendsViewModel.shared.fetchFriends()
                onLoginProgress?(nil)
            }
        }
    }

    func sendPasswordReset(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("sendPasswordReset error: \(error.localizedDescription)")
            } else {
                print("Password reset email sent (if account exists).")
            }
        }
    }

    func signInWithApple() {}
    func signInWithGoogle() {}

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("signOut error: \(error)")
        }
        self.user = nil
        self.isAuthenticated = false
        self.isEmailVerified = false
        FriendsViewModel.shared.currentUser = nil
        DispatchQueue.main.async {
            FriendsViewModel.shared.friends = []
        }
    }

    func deleteAccount() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        firebaseUser.delete { error in
            if let error = error {
                print("Error deleting Firebase user: \(error.localizedDescription)")
                return
            }
            if let uid = self.user?.uid {
                self.db.collection("users").document(uid).delete { err in
                    if let err = err {
                        print("Error deleting Firestore user doc: \(err.localizedDescription)")
                    }
                }
            }
            self.signOut()
        }
    }

    private func createUserDocument(
        for authUser: FirebaseAuth.User,
        name: String,
        avatar: String,
        bio: String? = nil,
        phone: String? = nil,
        notificationsEnabled: Bool = true,
        faceIDEnabled: Bool = false,
        avatarSeed: String = "defaultseed",
        avatarStyle: String = "adventurer",
        countryCode: String = CurrencyManager.deviceCountryAndCurrencyDefaults().country,
        currencyCode: String = CurrencyManager.deviceCountryAndCurrencyDefaults().currency,
        completion: ((Bool) -> Void)? = nil
    ) {
        let uid = authUser.uid
        var userDoc: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": authUser.email ?? "",
            "providers": authUser.providerData.map { $0.providerID },
            "emailVerified": authUser.isEmailVerified,
            "avatar": avatar,
            "avatarSeed": avatarSeed,      // DiceBear seed
            "avatarStyle": avatarStyle,    // DiceBear style
            "bio": bio ?? "",
            "phone": phone ?? "",
            "notificationsEnabled": notificationsEnabled,
            "faceIDEnabled": faceIDEnabled,
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp(),
            "groups": [],
            "friends": [],
            "deleted": false,
            "lastActivityAt": FieldValue.serverTimestamp(),
            "platform": "iOS"
        ]

        // Persist the user's country and currency codes for multi‑device syncing.
        userDoc["countryCode"] = countryCode
        userDoc["currencyCode"] = currencyCode
        db.collection("users").document(uid).setData(userDoc) { err in
            if let err = err {
                print("Failed to create user document: \(err.localizedDescription)")
                completion?(false)
                return
            }
            let userObj = User(id: uid, name: name, email: authUser.email)
            DispatchQueue.main.async {
                FriendsViewModel.shared.currentUser = userObj
            }
            completion?(true)
        }
    }

    func fetchUserDocument(uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Firestore fetch error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.user = nil
                    self.isAuthenticated = false
                    FriendsViewModel.shared.currentUser = nil
                    FriendsViewModel.shared.friends = []
                }
                return
            }
            guard let data = snapshot?.data() else {
                // ✅ Recovery path: user is authenticated in FirebaseAuth but their Firestore
                // profile doc is missing (common after project migrations or older test accounts).
                // Without this, the app sets currentUser=nil and everything (groups, expenses,
                // token saving) breaks.
                print("No Firestore user document found for uid \(uid). Creating a minimal profile...")
                self.ensureUserDocumentExists(uid: uid) { createdProfile in
                    guard let createdProfile else {
                        DispatchQueue.main.async {
                            self.user = nil
                            self.isAuthenticated = false
                            FriendsViewModel.shared.currentUser = nil
                            FriendsViewModel.shared.friends = []
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        self.user = createdProfile
                        self.isAuthenticated = true
                        self.isEmailVerified = createdProfile.emailVerified

                        let minimal = User(
                            id: createdProfile.uid,
                            name: createdProfile.name,
                            email: createdProfile.email,
                            avatar: createdProfile.avatar,
                            avatarSeed: createdProfile.avatarSeed,
                            avatarStyle: createdProfile.avatarStyle
                        )

                        FriendsViewModel.shared.currentUser = minimal
                        FriendsViewModel.shared.fetchFriends()
                    }
                }
                return
            }
            let decoded = self.decodeUserProfile(from: data)
            DispatchQueue.main.async {
                self.user = decoded
                self.isAuthenticated = true
                self.isEmailVerified = decoded.emailVerified

                // ⬇️ include avatar fields when pushing to FriendsVM
                let minimal = User(
                    id: decoded.uid,
                    name: decoded.name,
                    email: decoded.email,
                    avatar: decoded.avatar,
                    avatarSeed: decoded.avatarSeed,
                    avatarStyle: decoded.avatarStyle
                )

                FriendsViewModel.shared.currentUser = minimal
                FriendsViewModel.shared.fetchFriends()
            }
        }
    }

    /// Creates a minimal user profile document if it doesn't exist.
    /// This keeps the app functional (groups, expenses, push tokens) for older/test accounts.
    private func ensureUserDocumentExists(uid: String, completion: @escaping (UserProfile?) -> Void) {
        guard let authUser = Auth.auth().currentUser else {
            completion(nil)
            return
        }

        let defaults = CurrencyManager.deviceCountryAndCurrencyDefaults()
        let countryCode = defaults.country
        let currencyCode = defaults.currency

        let email = authUser.email ?? ""
        let nameGuess: String = {
            if let displayName = authUser.displayName, !displayName.isEmpty { return displayName }
            if let beforeAt = email.split(separator: "@").first { return String(beforeAt) }
            return "User"
        }()

        // Keep avatar values optional; app can later let user customize.
        let doc: [String: Any] = [
            "uid": uid,
            "name": nameGuess,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "countryCode": countryCode,
            "currencyCode": currencyCode
        ]

        db.collection("users").document(uid).setData(doc, merge: true) { err in
            if let err = err {
                print("❌ Failed to create missing user doc: \(err.localizedDescription)")
                completion(nil)
                return
            }

            // Construct the in-memory profile consistent with `decodeUserProfile` defaults.
            var profile = UserProfile(uid: uid, name: nameGuess, email: email)
            profile.countryCode = countryCode
            profile.currencyCode = currencyCode
            completion(profile)
        }
    }

    func updateAvatar(emoji: String) {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).updateData(["avatar": emoji]) { err in
            if let err = err {
                print("updateAvatar error: \(err.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.user?.avatar = emoji
                }
            }
        }
    }

    func updateDiceBearAvatar(seed: String, style: String) {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).updateData([
            "avatarSeed": seed,
            "avatarStyle": style
        ]) { err in
            if let err = err {
                print("updateDiceBearAvatar error: \(err.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.user?.avatarSeed = seed
                    self.user?.avatarStyle = style
                }
            }
        }
    }

    func updateProfile(name: String, phone: String, bio: String, avatar: String, avatarSeed: String, avatarStyle: String) {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).updateData([
            "name": name,
            "phone": phone,
            "bio": bio,
            "avatar": avatar,
            "avatarSeed": avatarSeed,
            "avatarStyle": avatarStyle
        ]) { err in
            if let err = err {
                print("updateProfile error: \(err.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.user?.name = name
                    self.user?.phone = phone
                    self.user?.bio = bio
                    self.user?.avatar = avatar
                    self.user?.avatarSeed = avatarSeed
                    self.user?.avatarStyle = avatarStyle
                }
            }
        }
    }

    func updateNotificationsEnabled(_ enabled: Bool) {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).updateData([
            "notificationsEnabled": enabled
        ]) { err in
            if let err = err {
                print("updateNotificationsEnabled error: \(err.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.user?.notificationsEnabled = enabled
                }
            }
        }
    }

    func updateFaceIDEnabled(_ enabled: Bool) {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).updateData([
            "faceIDEnabled": enabled
        ]) { err in
            if let err = err {
                print("updateFaceIDEnabled error: \(err.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.user?.faceIDEnabled = enabled
                }
            }
        }
    }

    // MARK: - Currency Settings
    /// Updates the authenticated user's locale preferences both locally and in Firestore.
    ///
    /// - Parameters:
    ///   - countryCode: Two‑letter ISO country code (e.g. "US").
    ///   - currencyCode: Three‑letter ISO currency code (e.g. "USD").
    func updateCurrency(countryCode: String, currencyCode: String) {
        guard let uid = user?.uid else { return }
        let normalizedCountry = countryCode.uppercased()
        let normalizedCurrency = currencyCode.uppercased()
        // Update Firestore document
        db.collection("users").document(uid).updateData([
            "countryCode": normalizedCountry,
            "currencyCode": normalizedCurrency
        ]) { error in
            if let error = error {
                print("Failed to update currency: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    // Update local user profile fields
                    self.user?.countryCode = normalizedCountry
                    self.user?.currencyCode = normalizedCurrency
                    // Propagate changes to CurrencyManager
                    CurrencyManager.shared.update(countryCode: normalizedCountry, currencyCode: normalizedCurrency)
                }
            }
        }
    }

    private func decodeUserProfile(from data: [String: Any]) -> UserProfile {
        // Derive locale/currency codes from Firestore, falling back to device defaults.
        let defaults = CurrencyManager.deviceCountryAndCurrencyDefaults()
        let fallbackCountry = defaults.country
        let fallbackCurrency = defaults.currency
        let countryCode = (data["countryCode"] as? String)?.uppercased() ?? fallbackCountry
        let currencyCode = (data["currencyCode"] as? String)?.uppercased() ?? fallbackCurrency
        // Update the CurrencyManager so UI reflects the persisted preference.
        CurrencyManager.shared.update(countryCode: countryCode, currencyCode: currencyCode)

        return UserProfile(
            uid: data["uid"] as? String ?? "",
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            providers: data["providers"] as? [String] ?? [],
            emailVerified: data["emailVerified"] as? Bool ?? false,
            avatar: data["avatar"] as? String,
            avatarSeed: data["avatarSeed"] as? String ?? "defaultseed",
            avatarStyle: data["avatarStyle"] as? String ?? "adventurer",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue() ?? Date(),
            bio: data["bio"] as? String,
            phone: data["phone"] as? String,
            notificationsEnabled: data["notificationsEnabled"] as? Bool ?? true,
            faceIDEnabled: data["faceIDEnabled"] as? Bool ?? false,
            groups: data["groups"] as? [String] ?? [],
            friends: data["friends"] as? [String] ?? [],
            pushToken: data["pushToken"] as? String,
            settings: data["settings"] as? [String: Bool] ?? [:],
            deleted: data["deleted"] as? Bool ?? false,
            lastActivityAt: (data["lastActivityAt"] as? Timestamp)?.dateValue() ?? Date(),
            platform: data["platform"] as? String ?? "iOS",
            countryCode: countryCode,
            currencyCode: currencyCode
        )
    }

    func setUser(from firebaseUser: FirebaseAuth.User) {
        let uid = firebaseUser.uid
        if let currentUser = self.user, currentUser.uid == uid {
            self.isAuthenticated = true
            self.isEmailVerified = firebaseUser.isEmailVerified

            // ⬇️ propagate avatar fields too
            FriendsViewModel.shared.currentUser = User(
                id: uid,
                name: currentUser.name,
                email: currentUser.email,
                avatar: currentUser.avatar,
                avatarSeed: currentUser.avatarSeed,
                avatarStyle: currentUser.avatarStyle
            )
            return
        }
        self.isAuthenticated = true
        self.isEmailVerified = firebaseUser.isEmailVerified
        self.fetchUserDocument(uid: uid)
    }
}
