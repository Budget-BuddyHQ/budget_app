{{flutter_js}}
{{flutter_build_config}}

// No service worker. Flutter's default one saved the whole app on the device
// and kept serving that copy after a new deploy, so phones that had opened
// the site before went on running an old build. index.html removes the one
// those phones already have.
_flutter.loader.load();
