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

    init() {
        // Listen for auth state changes (logout, user deleted, etc)
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                self.isAuthenticated = true
                self.isEmailVerified = user.isEmailVerified
                self.fetchUserDocument(uid: user.uid)
            } else {
                // This will cover: signOut, account deletion (even from another device), and token expiry
                self.isAuthenticated = false
                self.isEmailVerified = false
                self.user = nil
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
            if let user = result?.user {
                self.createUserDocument(for: user, name: name, avatar: avatar)
                user.sendEmailVerification { error in
                    if let error = error {
                        print("Failed to send verification: \(error.localizedDescription)")
                    } else {
                        print("Verification email sent!")
                    }
                }
                self.isAuthenticated = true
                self.isEmailVerified = user.isEmailVerified
                self.fetchUserDocument(uid: user.uid)
            } else {
                self.isAuthenticated = false
                self.isEmailVerified = false
                print("Signup error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let user = result?.user {
                self.isAuthenticated = true
                self.isEmailVerified = user.isEmailVerified
                self.fetchUserDocument(uid: user.uid)
            } else {
                self.isAuthenticated = false
                self.isEmailVerified = false
                print("Sign in error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func sendPasswordReset(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Apple/Google Auth (pseudo-code, fill in as needed)
    func signInWithApple() {
        // Use AuthenticationServices + FirebaseAuth
    }
    func signInWithGoogle() {
        // Use GoogleSignIn + FirebaseAuth
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.user = nil
        self.isAuthenticated = false
        self.isEmailVerified = false
    }

    func deleteAccount() {
        // Re-authenticate, delete user from Auth and Firestore, or mark as deleted
        guard let user = Auth.auth().currentUser else { return }
        user.delete { error in
            if error == nil {
                if let uid = self.user?.uid {
                    self.db.collection("users").document(uid).delete()
                }
                self.signOut()
            }
        }
    }

    // MARK: - Firestore User CRUD

    private func createUserDocument(for authUser: FirebaseAuth.User, name: String, avatar: String) {
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
        db.collection("users").document(uid).setData(userDoc)
    }

    func fetchUserDocument(uid: String) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Firestore fetch error: \(error.localizedDescription)")
                self.user = nil
                self.isAuthenticated = false
                return
            }
            guard let data = snapshot?.data() else {
                print("No Firestore user document found for uid \(uid)")
                self.user = nil
                self.isAuthenticated = false
                return
            }
            self.user = self.decodeUserProfile(from: data)
            self.isAuthenticated = true
            self.isEmailVerified = self.user?.emailVerified ?? false
        }
    }

    func updateAvatar(emoji: String) {
        guard let uid = user?.uid else { return }
        db.collection("users").document(uid).updateData(["avatar": emoji])
        user?.avatar = emoji
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
            return
        }
        self.isAuthenticated = true
        self.isEmailVerified = firebaseUser.isEmailVerified
        self.fetchUserDocument(uid: uid)
    }
}
