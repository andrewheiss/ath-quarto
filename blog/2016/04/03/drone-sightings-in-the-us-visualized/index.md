---
title: Drone sightings in the US, visualized
date: 2016-04-03
description: See where the FAA has reported hobbyist drone sightings from 2014–2016
categories: 
  - r
  - dataviz
  - hrbrmstr-challenge
---


For my first entry into [@hrbrmstr's new weekly data visualization challenge](https://rud.is/b/2016/03/30/introducing-a-weekly-r-python-js-etc-vis-challenge/), I made two plots related to the [dataset of unmanned aircraft (UAS) sightings](https://www.faa.gov/uas/resources/public_records/uas_sightings_report/). The [R code for these plots is on GitHub](https://github.com/andrewheiss/2016-13/tree/master/andrewheiss).

First, I was interested in the type of drones being spotted. When I think of drones, I typically think of the ones the CIA and Air Force have flying over Yemen, Somalia, Afghanistan, and Pakistan shooting at suspected ISIS and Al-Qaeda members. To see if that's the case with these UAS sightings, I mapped out all US-based Air Force bases and all drone sightings, assuming that any military drone sightings would happen near bases.

![UAS sightings and Air Force bases](drones_af_map.png)

While some sightings do occur near bases (like in Eastern Washington, Eastern Colorado, and Nebraska, for example), most don't. In fact, in Texas, there are almost no UAS sightings near Air Force bases. Thus, even though there are [documented cases of military drones being used in the US](http://www.engadget.com/2016/03/09/pentagon-deployed-drones-in-us/), these sightings are most definitely not military drones (unless they're all drones coming from unmapped CIA bases). They're quadrocopters and other hobbyist drones.

I noticed that in some cases (like Salt Lake City, Las Vegas, and Phoenix), almost all sightings were clustered around Air Force bases. However, this is not because the military is spying on everyone in the west, but because that's where everyone lives—very few hobbyist drone operators live in the Utah, Nevada, or Arizona deserts. Drone sightings (both the number of sightings and their location) might just be a function of state population.

For my second plot, I looked at the relationship between drone sightings and state population to see if there are states that see more drones than normal. The results were surprising.

![Drone sightings per capita](drones_states.png)

While more populous states like New York, California, Florida, and Texas predictably see more drones (since there are likely more hobbyists), Washington, DC by far sees the most drone activity per capita. Maybe everyone there really is just trying to spy on Congress and the [President](http://www.cnn.com/2015/05/14/politics/white-house-drone-arrest/), even though [drones are ostensibly banned in DC](http://www.usatoday.com/story/news/2015/10/09/drone-crash-white-house-ellipse-us-park-police-federal-aviation-administration/73641812/).
