---
name: cr-commission-vipassana
description: >-
  Transforme un brouillon de compte rendu de réunion de commission en deux
  fichiers HTML (CR interne détaillé + CR public synthétique) mis en forme avec
  la police et l'interligne du modèle Word de l'association, prêts à coller dans
  Word Online. Use when the user mentions un compte rendu, un CR, une commission,
  une réunion, ou demande de générer un CR interne et/ou public.
disable-model-invocation: true
---

# Comptes rendus de commission (Vipassana)

Prend un brouillon de CR rapidement écrit et produit **deux fichiers HTML**
distincts, copiables dans Word Online en gardant la mise en forme.

## Approche

Coller du HTML **rendu dans le navigateur** (pas le code source) dans Word
Online conserve gras, italique, listes — mais **pas** les Styles Titre (Word
Online aplatit `<h1>`/`<h2>`). Pour que le rendu ressemble au document de
l'association, on **reproduit en CSS inline la police et l'interligne du modèle**
(`assets/template.docx`). Les titres restent donc du texte mis en forme (bonne
police/taille), pas des Styles Word, mais visuellement c'est cohérent.

### Réglages CSS extraits du modèle (`assets/template.docx`)

```css
body { font-family: 'Noto Sans', sans-serif; font-size: 10pt; line-height: 1.16; color: #000; }
p  { margin: 0 0 4pt 0; }
h1 { font-family: 'Noto Sans', sans-serif; font-size: 18pt; font-weight: bold; text-align: center; line-height: 1.16; margin: 0pt 0 16pt 0; }
h2 { font-family: 'Noto Sans', sans-serif; font-size: 13pt; font-weight: bold; text-align: left;   line-height: 1.16; margin: 14pt 0 4pt 0; }
ul { margin: 0 0 4pt 0; }
li { margin: 0 0 4pt 0; }
```

- Corps (Normal) : **Noto Sans 10 pt**, interligne 1.16, 4 pt après.
- Titre 1 : **Noto Sans 18 pt gras, centré**, 16 pt après.
- Titre 2 : **Noto Sans 13 pt gras, aligné à gauche**, 14 pt avant.

Si le modèle change, ré-extraire ces valeurs depuis `assets/template.docx`
(`word/styles.xml` : Normal, Heading1, Heading2 ; `word/theme/theme1.xml` pour
les polices de thème ; `sz` en demi-points, `spacing` en 1/20 pt, `line` auto =
val/240).

## Workflow

1. Lire le brouillon fourni.
2. Demander/déduire les infos manquantes : **nom de la commission**, **date**,
   **liste des présents**. Si absentes du brouillon, demander avant de générer.
3. Améliorer le contenu : orthographe, clarté, regroupement logique des idées.
   Pour le CR public, regrouper les actions par **objectif**.
4. Générer **2 fichiers HTML** dans `~/Téléchargements/` (avec le bloc `<style>`
   ci-dessus) :
   - `cr-interne-<commission>-<date>.html`
   - `cr-public-<commission>-<date>.html`
   (`<date>` au format `AAAA-MM-JJ`, `<commission>` en minuscules sans accents.)
   Astuce : si l'outil d'écriture refuse de créer un fichier inexistant dans ce
   dossier, faire d'abord `touch` du chemin puis écrire.
5. **Ouvrir automatiquement les deux fichiers dans le navigateur** avec
   `xdg-open` (les liens markdown vers des fichiers locaux ne sont pas
   cliquables dans le chat Cursor) :
   `xdg-open ~/Téléchargements/cr-interne-<commission>-<date>.html`
   `xdg-open ~/Téléchargements/cr-public-<commission>-<date>.html`
6. Indiquer à l'utilisateur : dans chaque onglet, tout sélectionner (Ctrl+A),
   copier (Ctrl+C), coller dans le document Word Online.

## CR interne

Contenu détaillé, réservé à la commission.

- `<h1>` : `CR commission <nom> <date>` (ex. "CR commission cuisine 27 juin 2026")
- Présents en **italique** : `<p><em>Présents : ...</em></p>`
- Section `<h2>Points d'action</h2>` puis `<ul>` regroupant **chaque action
  décidée**, avec le **nom du responsable** (ex. "Acheter un four — Marie").
  Cette liste sert à vérifier l'avancement à la réunion suivante.
- Sections classiques : `<h2>` titre + `<p>` texte = le CR détaillé.
  Dans les paragraphes, mettre en valeur les actions à faire avec 👉.

### Gabarit CR interne

```html
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>CR interne</title>
<style>
  body { font-family: 'Noto Sans', sans-serif; font-size: 10pt; line-height: 1.16; color: #000; }
  p  { margin: 0 0 4pt 0; }
  h1 { font-family: 'Noto Sans', sans-serif; font-size: 18pt; font-weight: bold; text-align: center; line-height: 1.16; margin: 0pt 0 16pt 0; }
  h2 { font-family: 'Noto Sans', sans-serif; font-size: 13pt; font-weight: bold; text-align: left;   line-height: 1.16; margin: 14pt 0 4pt 0; }
  ul { margin: 0 0 4pt 0; }
  li { margin: 0 0 4pt 0; }
</style>
</head>
<body>
  <h1>CR commission cuisine 27 juin 2026</h1>
  <p><em>Présents : Marie, Paul, Sophie, Jean</em></p>

  <h2>Points d'action</h2>
  <ul>
    <li>Acheter un four professionnel — Marie</li>
    <li>Demander 3 devis pour les plans de travail — Paul</li>
    <li>Rédiger la liste du matériel manquant — Sophie</li>
  </ul>

  <h2>Équipement de la cuisine</h2>
  <p>Le four actuel est en panne. Après discussion, nous optons pour un modèle
  professionnel d'occasion. 👉 Marie se charge de l'achat avant la prochaine
  session.</p>

  <h2>Aménagement du réfectoire</h2>
  <p>Les tables sont en mauvais état. 👉 Paul demande 3 devis pour des plans de
  travail neufs.</p>
</body>
</html>
```

## CR public

Synthèse communiquée à tout le monde, mise en forme plus stricte, moins de
détails.

- Pour chaque **objectif** : `<h2>` titre (ex. "Équiper la cuisine",
  "Aménager le réfectoire").
- Puis un `<p>` en **phrases normales** (synthétique mais agréable à lire, pas de
  fragments télégraphiques). 1 à 3 phrases qui résument ce qui a été décidé/fait
  pour cet objectif. Réserver les `<ul>` aux énumérations qui le justifient.
- **Aucun nom** de personne (ni qui a fait, ni qui fera).
- Faire ressortir clairement les **demandes de budget** et **accords de
  principe** avec `<strong>` et un préfixe explicite. Ne pas ajouter de mention
  « à valider en CA ».

### Gabarit CR public

```html
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>CR public</title>
<style>
  body { font-family: 'Noto Sans', sans-serif; font-size: 10pt; line-height: 1.16; color: #000; }
  p  { margin: 0 0 4pt 0; }
  h1 { font-family: 'Noto Sans', sans-serif; font-size: 18pt; font-weight: bold; text-align: center; line-height: 1.16; margin: 0pt 0 16pt 0; }
  h2 { font-family: 'Noto Sans', sans-serif; font-size: 13pt; font-weight: bold; text-align: left;   line-height: 1.16; margin: 14pt 0 4pt 0; }
  ul { margin: 0 0 4pt 0; }
  li { margin: 0 0 4pt 0; }
</style>
</head>
<body>
  <h1>Commission cuisine — 27 juin 2026</h1>

  <h2>Équiper la cuisine</h2>
  <p>Le four hors service va être remplacé par un modèle professionnel d'occasion.
  <strong>Demande de budget : 1 200 € pour l'achat du four.</strong></p>

  <h2>Aménager le réfectoire</h2>
  <p>Face à l'usure des tables, une recherche de devis est en cours pour de
  nouveaux plans de travail. <strong>Un accord de principe est demandé pour la
  rénovation du réfectoire.</strong></p>
</body>
</html>
```

## Rappel

- `<h1>` = titre centré gras 18 pt, `<h2>` = titre gras 13 pt, `<p>` = corps,
  tout en Noto Sans ;
  `<em>` = italique, `<strong>` = gras, `<ul><li>` = puces, 👉 inline.
- Ne pas coller le code HTML brut : ouvrir le fichier dans le navigateur puis
  copier le rendu.
