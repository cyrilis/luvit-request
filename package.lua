return {
    name = "cyrilis/request",
    version = "0.0.1",
    homepage = "https://github.com/cyrilis/luvit-request",
    description = "Another light-weight progressive request library crafted for flexibility, readability, and a low learning curve.",
    tags = {"luvit", "request", "networks"},
    private = false,
    license = "MIT",
    author = { name = "Cyril Hou" },
    dependencies = {
        "luvit/require",
        "luvit/pretty-print",
    },
    files = {
        "**.*",
        "!request"
        "!test*",
        "!.DS_Store",
        "!.git/*",
        "!.idea/*",
        "!.gitignore"
    }
}