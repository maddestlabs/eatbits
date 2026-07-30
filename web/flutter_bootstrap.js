{{flutter_js}}
{{flutter_build_config}}

const userConfig = {
  canvasKitBaseUrl: "canvaskit/",
};

_flutter.loader.load({
  config: userConfig,
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
    timeoutMillis: 6000,
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine(userConfig);
    await appRunner.runApp();

    // Trigger offline pre-caching of all PWA resources (canvaskit, fonts, icons)
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.ready.then((registration) => {
        if (registration.active) {
          registration.active.postMessage('downloadOffline');
        }
      });
    }
  }
}).catch(function(err) {
  console.warn("Service worker load warning:", err);
  // Failsafe: if service worker failed/timed out, unregister old workers so next reload is clean
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
      for (let r of registrations) {
        r.unregister();
      }
    });
  }
});
