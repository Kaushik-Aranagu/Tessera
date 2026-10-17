# Review #719 at 50e02ce1 (Builder B, G4 AS PASTED)

Static. RecipePage.swift: AS PASTED section is wrapped in `if let source = RecipeCopy.pasted(sourceText)`; pasted() returns nil for nil, "" or whitespace-only.
- Link-read recipes: RecipeImport.swift:109 builds ParsedRecipe with source "", so sourceText is empty or unset and the section never shows. Pasted text path (CreateRecipe, SecretWords.cut of the source) shows as before; a text that is only private lines cuts to empty and also hides, which is right.
- Nothing else moves: the rest of RecipeOriginal is untouched; RecipeCopy.pasted is an added static. AsPastedTests cover nil, "", blank, shown.

PASS. Needs Design only if the page spacing without the section matters (none expected).
