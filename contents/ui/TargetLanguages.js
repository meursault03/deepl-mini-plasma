.pragma library

var targetLanguages = [
    { code: "ACE", name: "Acehnese" },
    { code: "AF", name: "Afrikaans" },
    { code: "AN", name: "Aragonese" },
    { code: "AR", name: "Arabic" },
    { code: "AS", name: "Assamese" },
    { code: "AY", name: "Aymara" },
    { code: "AZ", name: "Azerbaijani" },
    { code: "BA", name: "Bashkir" },
    { code: "BE", name: "Belarusian" },
    { code: "BG", name: "Bulgarian" },
    { code: "BHO", name: "Bhojpuri" },
    { code: "BN", name: "Bengali" },
    { code: "BR", name: "Breton" },
    { code: "BS", name: "Bosnian" },
    { code: "CA", name: "Catalan" },
    { code: "CEB", name: "Cebuano" },
    { code: "CKB", name: "Kurdish (Sorani)" },
    { code: "CS", name: "Czech" },
    { code: "CY", name: "Welsh" },
    { code: "DA", name: "Danish" },
    { code: "DE", name: "German" },
    { code: "DE-CH", name: "German (Swiss)" },
    { code: "DE-DE", name: "German" },
    { code: "EL", name: "Greek" },
    { code: "EN", name: "English" },
    { code: "EN-GB", name: "English (British)" },
    { code: "EN-US", name: "English (American)" },
    { code: "EO", name: "Esperanto" },
    { code: "ES", name: "Spanish" },
    { code: "ES-419", name: "Spanish (Latin American)" },
    { code: "ET", name: "Estonian" },
    { code: "EU", name: "Basque" },
    { code: "FA", name: "Persian" },
    { code: "FI", name: "Finnish" },
    { code: "FR", name: "French" },
    { code: "FR-CA", name: "French (Canadian)" },
    { code: "FR-FR", name: "French" },
    { code: "GA", name: "Irish" },
    { code: "GL", name: "Galician" },
    { code: "GN", name: "Guarani" },
    { code: "GOM", name: "Konkani" },
    { code: "GU", name: "Gujarati" },
    { code: "HA", name: "Hausa" },
    { code: "HE", name: "Hebrew" },
    { code: "HI", name: "Hindi" },
    { code: "HR", name: "Croatian" },
    { code: "HT", name: "Haitian Creole" },
    { code: "HU", name: "Hungarian" },
    { code: "HY", name: "Armenian" },
    { code: "ID", name: "Indonesian" },
    { code: "IG", name: "Igbo" },
    { code: "IS", name: "Icelandic" },
    { code: "IT", name: "Italian" },
    { code: "JA", name: "Japanese" },
    { code: "JV", name: "Javanese" },
    { code: "KA", name: "Georgian" },
    { code: "KK", name: "Kazakh" },
    { code: "KMR", name: "Kurdish (Kurmanji)" },
    { code: "KO", name: "Korean" },
    { code: "KY", name: "Kyrgyz" },
    { code: "LA", name: "Latin" },
    { code: "LB", name: "Luxembourgish" },
    { code: "LMO", name: "Lombard" },
    { code: "LN", name: "Lingala" },
    { code: "LT", name: "Lithuanian" },
    { code: "LV", name: "Latvian" },
    { code: "MAI", name: "Maithili" },
    { code: "MG", name: "Malagasy" },
    { code: "MI", name: "Maori" },
    { code: "MK", name: "Macedonian" },
    { code: "ML", name: "Malayalam" },
    { code: "MN", name: "Mongolian" },
    { code: "MR", name: "Marathi" },
    { code: "MS", name: "Malay" },
    { code: "MT", name: "Maltese" },
    { code: "MY", name: "Burmese" },
    { code: "NB", name: "Norwegian (bokmål)" },
    { code: "NE", name: "Nepali" },
    { code: "NL", name: "Dutch" },
    { code: "OC", name: "Occitan" },
    { code: "OM", name: "Oromo" },
    { code: "PA", name: "Punjabi" },
    { code: "PAG", name: "Pangasinan" },
    { code: "PAM", name: "Kapampangan" },
    { code: "PL", name: "Polish" },
    { code: "PRS", name: "Dari" },
    { code: "PS", name: "Pashto" },
    { code: "PT", name: "Portuguese" },
    { code: "PT-BR", name: "Portuguese (Brazilian)" },
    { code: "PT-PT", name: "Portuguese (European)" },
    { code: "QU", name: "Quechua" },
    { code: "RO", name: "Romanian" },
    { code: "RU", name: "Russian" },
    { code: "SA", name: "Sanskrit" },
    { code: "SCN", name: "Sicilian" },
    { code: "SK", name: "Slovak" },
    { code: "SL", name: "Slovenian" },
    { code: "SQ", name: "Albanian" },
    { code: "SR", name: "Serbian" },
    { code: "ST", name: "Sesotho" },
    { code: "SU", name: "Sundanese" },
    { code: "SV", name: "Swedish" },
    { code: "SW", name: "Swahili" },
    { code: "TA", name: "Tamil" },
    { code: "TE", name: "Telugu" },
    { code: "TG", name: "Tajik" },
    { code: "TH", name: "Thai" },
    { code: "TK", name: "Turkmen" },
    { code: "TL", name: "Tagalog" },
    { code: "TN", name: "Tswana" },
    { code: "TR", name: "Turkish" },
    { code: "TS", name: "Tsonga" },
    { code: "TT", name: "Tatar" },
    { code: "UK", name: "Ukrainian" },
    { code: "UR", name: "Urdu" },
    { code: "UZ", name: "Uzbek" },
    { code: "VI", name: "Vietnamese" },
    { code: "WO", name: "Wolof" },
    { code: "XH", name: "Xhosa" },
    { code: "YI", name: "Yiddish" },
    { code: "YUE", name: "Cantonese" },
    { code: "ZH", name: "Chinese" },
    { code: "ZH-HANS", name: "Chinese (simplified)" },
    { code: "ZH-HANT", name: "Chinese (traditional)" },
    { code: "ZU", name: "Zulu" }
]

function contains(code) {
    var normalized = String(code || "").toUpperCase()
    return targetLanguages.some(function(language) {
        return language.code === normalized
    })
}

function normalize(code) {
    var normalized = String(code || "").toUpperCase()
    return contains(normalized) ? normalized : "EN-US"
}

function labelFor(code) {
    var normalized = normalize(code)
    for (var index = 0; index < targetLanguages.length; index += 1) {
        if (targetLanguages[index].code === normalized)
            return targetLanguages[index].name
    }
    return "English (American)"
}

function filter(query) {
    var normalized = String(query || "").trim().toLowerCase()
    if (!normalized)
        return targetLanguages.slice()
    return targetLanguages.filter(function(language) {
        return language.code.toLowerCase().indexOf(normalized) !== -1 ||
            language.name.toLowerCase().indexOf(normalized) !== -1
    })
}
