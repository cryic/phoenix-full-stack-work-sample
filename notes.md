# What was built/not built

- The output of `fly status` in the `flyctl` tool has 3 main sections: *App*, *Deployment Status*, and *Instances*. The information from the *App* section was mostly on the page, spread through the header and *App* section, so I focused on bringing *Deployment Status* and *Instances* over to the dashboard.
- I kept all fields from `fly status`, not wanting to cut/add anything for this exercise.
- The fields "Instances" in *Deployment Status* and "Health Checks" and "Created" in *Instances* had formatting that I brought over from [status.go](https://github.com/superfly/flyctl/blob/master/cmd/status.go) and its presenters from `flyctl`.
- I set the data refresh to every 5 seconds, which imitates the `--watch` option defaults.
- I switched the timeline to show the most recent entries vs the initial ones, just to make sure that the version info in *Instances* matched the timeline info.

## Future Improvements

- Research/get feedback on the idiomatic-ness(?) of the helper functions in `fly_web/live/app_live/show.ex`. I'm still getting a sense of when using some of Elixir's neat features might get in the way of clarity. For example, in `show.ex#health_checks/1`, I used function pipelining to transform the list of counts and associated text. What is going on in each step seems clear, however, the reverses and joins might seem unnecessary when you could just loop through and act on each item.

- The page layout for large screens could use tightening up. The other content blocks need to move around the timeline column, creating extra spacing underneath the timeline. My vertical orientation of *Deployment Status* contributes to that some, however, when *Deployment Status* is missing (due to the GraphQL api not returning deploy info), the spacing is still off.

- Tables sideways scrolling in single-column screen size. *Instances* has many fields, so the table scrolls horizontally when the page goes to a single-column view. For apps with multiple instances, horizontal orientation of the table is really useful for quick comparison and noticing any discrepancies, however, the sideways scrolling is a little annoying. There may be another layout for that info that would allow for minimal scrolling but easy instance comparison.

- Always have Last Deployment info. Currently, the GraphQL endpoint for apps returns deploy info for about 2-3 hours after the last deploy. When the deploy data isn't returned, the *Deployment Status* block disappears. I think it is useful to have that info available all the time. This would require research/work on the API, why it currently acts that way, and weigh drawbacks for always including that info.

- Going beyond `fly status`. With most of `status` on the page, there could be other features ported from `flyctl`. A few ideas:
  - Each Instance could have a link to show the most recent logs.
  - Health checks could have a dropdown/more info to show what checks were run.
  - Each Instance short ID could link to ssh into the VM.
  - Many features of the page depend on the goal of the dashboard: if it should be a view-only or if it should be seen as an alternative to `flyctl`.

## Determining success

- General page views going up might tell if users are curious to see status on the dashboard.
- In the dashboard's current state, users might see that there are no actions to be taken on the page, so prefer to use `flyctl` since they can actually perform actions there. If web dashboard usage goes up, would usage of `fly status` go down? Do users prefer to see status on the dashboard or via commandline? This may be difficult to correlate.
- If users are sending dashboard screenshots as app instance bug reports, that may be a good sign that users find the dashboard reporting to be helpful for checking app status.
