let inherited_env = $env | columns

if "http_proxy" in $inherited_env { hide-env http_proxy }
if "https_proxy" in $inherited_env { hide-env https_proxy }
if "all_proxy" in $inherited_env { hide-env all_proxy }
if "no_proxy" in $inherited_env { hide-env no_proxy }
if "HTTP_PROXY" in $inherited_env { hide-env HTTP_PROXY }
if "HTTPS_PROXY" in $inherited_env { hide-env HTTPS_PROXY }
if "ALL_PROXY" in $inherited_env { hide-env ALL_PROXY }
if "NO_PROXY" in $inherited_env { hide-env NO_PROXY }
