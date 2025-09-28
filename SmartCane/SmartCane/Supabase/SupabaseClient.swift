//
//  SupabaseClient.swift
//  SmartCane
//
//  Created by Haya Alfakieh on 9/18/25.

import Foundation
import Supabase

enum SupaSecrets {
    static let url: URL = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: raw) else {
            fatalError("❌ Missing SUPABASE_URL in Info.plist")
        }
        return url
    }()

    static let key: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String else {
            fatalError("❌ Missing SUPABASE_KEY in Info.plist")
        }
        return key
    }()
}
let supabase = SupabaseClient(
    supabaseURL: SupaSecrets.url,
    supabaseKey: SupaSecrets.key
)
