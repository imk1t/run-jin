import Foundation
import Supabase

enum SupabaseConfig {
    static var url: URL {
        guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              let url = URL(string: urlString) else {
            #if DEBUG
            return URL(string: "http://127.0.0.1:54321")!
            #else
            fatalError("SUPABASE_URL not configured in Info.plist")
            #endif
        }
        return url
    }

    static var anonKey: String {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            #if DEBUG
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
            #else
            fatalError("SUPABASE_ANON_KEY not configured in Info.plist")
            #endif
        }
        return key
    }
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)
