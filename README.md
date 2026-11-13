# Le Dépanneur — version de test

Application Flutter (Android) : trouver un professionnel ou un service de proximité selon sa localisation.

## Obtenir l'APK sur votre téléphone
1. Créez un dépôt GitHub (ex. `RymeTVNews/le-depanneur`) et envoyez-y le contenu de ce dossier (le dossier `.github` compris).
2. L'onglet **Actions** compile l'APK automatiquement (≈ 5–8 min). Sinon : Actions > « Compiler l'APK Android » > Run workflow.
3. Sur votre téléphone, ouvrez la page **Releases** du dépôt, téléchargez `le-depanneur-test.apk`, ouvrez-le et autorisez l'installation depuis cette source.

## Contenu de la version de test
- Inscription par courriel, essai de 7 jours, puis 5 $/an (paiement **simulé**).
- Recherche par métier/mot-clé, triée par distance (GPS). Profils de démonstration générés autour de vous.
- Inscription des professionnels : personne (photo d'identité, pièce d'identité, téléphone) ou entreprise (nom, photo, téléphone, adresse).
- Fiche du professionnel : photo, téléphone (bouton Appeler), adresse (carte), badge de vérification. La pièce d'identité n'est jamais montrée aux clients.

## Serveur (Supabase)
1. supabase.com > New project.
2. SQL Editor : coller `supabase/schema.sql` et cliquer Run.
3. Authentication > Emails > modèle « Magic link » : remplacer le lien par `Votre code : {{ .Token }}`.
4. Project Settings > API : copier l'URL et la clé `anon` dans `lib/config.dart`.

## Limites connues (à faire avant publication)
- Les courriels de connexion sont limités (≈ 2/heure) avec le service d'envoi intégré de Supabase : configurer un SMTP pour la production.
- Aucune vérification humaine/automatique des pièces d'identité.
- Paiement réel : Google Play Billing (abonnement avec essai gratuit de 7 jours).
