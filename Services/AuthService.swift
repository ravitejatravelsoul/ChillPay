import Foundation
import FirebaseAuth
import FirebaseFirestore

/// AuthService handles Firebase Authentication + basic Firestore user document CRUD.
/// This version ensures FriendsViewModel.shared.currentUser is set/cleared so
/// add-or-invite friend flows have a valid current user.
class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var user: UserProfile?
    @Published var isAuthenticated = false
    @Published var isEmailVerified = false

    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Listen for auth state changes (logout, user deleted, etc)
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                self.isAuthenticated = true
                self.isEmailVerified = user.isEmailVerified
                // Fetch the Firestore user document and ensure FriendsViewModel is updated
                self.fetchUserDocument(uid: user.uid)
            } else {
                // This will cover: signOut, account deletion (even from another device), and token expiry
                self.isAuthenticated = false
                self.isEmailVerified = false
                self.user = nil
                // Clear friends VM
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
    func signUpWithEmail(email: String, password: String, name: String, avatar: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Signup error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                }
                return
            }
            guard let firebaseUser = result?.user else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                }
                print("Signup: no firebase user returned")
                return
            }

            // Create Firestore user document and set FriendsViewModel current user in the completion
            self.createUserDocument(for: firebaseUser, name: name, avatar: avatar) { created in
                if created {
                    // fetch the user doc to populate local state
                    self.fetchUserDocument(uid: firebaseUser.uid)
                } else {
                    print("Warning: user document creation failed or returned false")
                    self.fetchUserDocument(uid: firebaseUser.uid)
                }
            }

            // Send verification (non-blocking)
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

    func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign in error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                }
                return
            }
            guard let firebaseUser = result?.user else {
                print("Sign in: no firebase user returned")
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                }
                return
            }

            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.isEmailVerified = firebaseUser.isEmailVerified
            }

            // Fetch user doc and ensure FriendsViewModel.currentUser is set
            self.fetchUserDocument(uid: firebaseUser.uid)
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

    // MARK: - Apple/Google Auth (pseudo-code, fill in as needed)
    func signInWithApple() {
        // Use AuthenticationServices + FirebaseAuth
    }
    func signInWithGoogle() {
        // Use GoogleSignIn + FirebaseAuth
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("signOut error: \(error)")
        }
        // Clear local state
        self.user = nil
        self.isAuthenticated = false
        self.isEmailVerified = false
        // Clear FriendsViewModel
        FriendsViewModel.shared.currentUser = nil
        DispatchQueue.main.async {
            FriendsViewModel.shared.friends = []
        }
    }

    func deleteAccount() {
        // Re-authenticate, delete user from Auth and Firestore, or mark as deleted
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

    // MARK: - Firestore User CRUD

    /// Create or overwrite a user document for the given FirebaseAuth user.
    /// Calls completion(true) on successful write (or when write returns no error).
    private func createUserDocument(for authUser: FirebaseAuth.User, name: String, avatar: String, completion: ((Bool) -> Void)? = nil) {
        let uid = authUser.uid
        let userDoc: [String: Any] = [
            "uid": uid,
            "name": name,
            "email": authUser.email ?? "",
            "providers": authUser.providerData.map { $0.providerID },
            "emailVerified": authUser.isEmailVerified,
            "avatar": avatar,
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
            // Ensure FriendsViewModel has the current user after create
            let userObj = User(id: uid, name: name, email: authUser.email)
            DispatchQueue.main.async {
                FriendsViewModel.shared.currentUser = userObj
            }
            completion?(true)
        }
    }

    /// Fetch Firestore user document and populate local `user` (UserProfile).
    /// Also sets FriendsViewModel.shared.currentUser to a minimal `User`.
    func fetchUserDocument(uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Firestore fetch error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.user = nil
                    self.isAuthenticated = false
                    // Clear friends VM just in case
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
                // Mirror a lightweight User model into FriendsViewModel for friend operations
                let minimal = User(id: decoded.uid, name: decoded.name, email: decoded.email)
                FriendsViewModel.shared.currentUser = minimal
                // Optionally refresh friends list immediately
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

    // MARK: - UserProfile Decoding
    private func decodeUserProfile(from data: [String: Any]) -> UserProfile {
        return UserProfile(
            uid: data["uid"] as? String ?? "",
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            providers: data["providers"] as? [String] ?? [],
            emailVerified: data["emailVerified"] as? Bool ?? false,
            avatar: data["avatar"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue() ?? Date(),
            bio: data["bio"] as? String,
            groups: data["groups"] as? [String] ?? [],
            friends: data["friends"] as? [String] ?? [],
            pushToken: data["pushToken"] as? String,
            settings: data["settings"] as? [String: Bool] ?? [:],
            deleted: data["deleted"] as? Bool ?? false,
            lastActivityAt: (data["lastActivityAt"] as? Timestamp)?.dateValue() ?? Date(),
            platform: data["platform"] as? String ?? "iOS"
        )
    }

    // MARK: - Set user from FirebaseAuth.User (for persistent login on relaunch)
    func setUser(from firebaseUser: FirebaseAuth.User) {
        let uid = firebaseUser.uid
        // If already have the user profile in memory, skip fetch
        if let currentUser = self.user, currentUser.uid == uid {
            self.isAuthenticated = true
            self.isEmailVerified = firebaseUser.isEmailVerified
            // Also ensure friends VM is set
            FriendsViewModel.shared.currentUser = User(id: uid, name: currentUser.name, email: currentUser.email)
            return
        }
        self.isAuthenticated = true
        self.isEmailVerified = firebaseUser.isEmailVerified
        self.fetchUserDocument(uid: uid)
    }
}
