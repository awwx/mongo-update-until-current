Package.describe({
  summary: "Atomic Mongo updates using the Update If Current pattern"
});

Package.on_use(function (api) {
  api.use(['coffeescript', 'mongo-livedata', 'obj'], ['client', 'server']);
  api.export("updateUntilCurrent");
  api.add_files('client.coffee', 'client');
  api.add_files('server.coffee', 'server');
});

Package.on_test(function (api) {
  api.use(['coffeescript', 'tinytest', 'mongo-update-until-current'], ['client', 'server']);
  api.add_files(['client-tests.coffee'], 'client');
  api.add_files(['server-tests.coffee'], 'server');
});
