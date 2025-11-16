import Foundation
import FirebaseAuth
import FirebaseFirestore

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
                avatarStyle: avatarStyle
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
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.isEmailVerified = firebaseUser.isEmailVerified
            }
            self.tryFetchUserDocumentWithRetry(uid: firebaseUser.uid, attempts: 5, delay: 0.4, onLoginProgress: onLoginProgress)
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
        completion: ((Bool) -> Void)? = nil
    ) {
        let uid = authUser.uid
        let userDoc: [String: Any] = [
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
                print("No Firestore user document found for uid \(uid)")
                DispatchQueue.main.async {
                    self.user = nil
                    self.isAuthenticated = false
                    FriendsViewModel.shared.currentUser = nil
                    FriendsViewModel.shared.friends = []
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

    private func decodeUserProfile(from data: [String: Any]) -> UserProfile {
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
            platform: data["platform"] as? String ?? "iOS"
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
