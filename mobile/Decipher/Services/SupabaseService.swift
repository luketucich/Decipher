import Foundation
import Supabase

enum SupabaseConfig {
    static let supabaseURL = URL(string: "https://tiipnyyxsvigodgrrzfd.supabase.co")!

    // This key is safe to ship in iOS, but keep it scoped to anon/publishable usage only.
    static let supabaseAnonKey = "sb_publishable_DosMc7amQhNErfrrhswfQA_J4fyAyQh"
}

struct SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: SupabaseConfig.supabaseURL,
        supabaseKey: SupabaseConfig.supabaseAnonKey,
        options: SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true)
        )
    )
}
