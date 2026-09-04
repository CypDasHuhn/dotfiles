return {
  project_config = {
    pattern = "^package%.json$",
    files = {
      "components.json",
      "eslint.config.js",
      "favicon.ico",
      "index.html",
      "package-lock.json",
      "tsconfig.json",
      "tsconfig.node.json",
      "vite.config.ts",
      "vitest.config.ts",
    },
  },
  app_vue_files = {
    pattern = "^App%.vue$",
    files = {
      "auto-imports.d.ts",
      "components.d.ts",
      "devextreme-license.ts",
      "main.ts",
      "style.css",
      "typed-router.d.ts",
      "vite-env.d.ts",
    },
  },
  vue_tests = {
    pattern = "(.+)%.vue$",
    files = { "%1.spec.vue", "%1.spec.ts" },
  },
  typescript_tests = {
    pattern = "(.+)%.ts$",
    files = { "%1.spec.ts" },
  },
  kotlin_gradle = {
    pattern = "^build%.gradle.kts$",
    files = { "gradle.properties", "gradlew", "gradlew.bat", "settings.gradle.kts", "kls_database.db" },
  }
}
