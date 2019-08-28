workflow "Test" {
  on = "push"
  resolves = ["docker://cloudfoundry/capi:ruby-units"]
}

action "docker://cloudfoundry/capi:ruby-units" {
  uses = "docker://cloudfoundry/capi:ruby-units"
  args = "bundle exec rake"
}
