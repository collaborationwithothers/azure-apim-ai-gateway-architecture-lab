targetScope = 'subscription'

@description('Non-sensitive spoke network contract consumed by later implementation slices.')
param spokeNetwork object

// Keep deployment outputs non-sensitive. Deployment outputs are stored in
// deployment history and can be read by users with deployment read access.
output spokeNetwork object = spokeNetwork
