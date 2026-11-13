// Valeurs à copier depuis Supabase : Project Settings > API.
// La clé « anon / publishable » est conçue pour être publique (la sécurité
// repose sur les règles RLS de supabase/schema.sql). Ne mettez JAMAIS la clé « service_role ».
const String kSupabaseUrl = 'https://VOTRE-PROJET.supabase.co';
const String kSupabaseAnonKey = 'VOTRE_CLE_ANON';

// Affiche aussi des profils de démonstration autour de l'utilisateur.
const bool kShowDemo = true;
