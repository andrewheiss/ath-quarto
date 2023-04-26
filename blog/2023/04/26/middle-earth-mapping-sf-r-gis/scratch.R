# Interactive map

library(tmap)

tmap_mode("view")

fancy_map <- tm_basemap(NULL) +  # No basemap, since we're not in the real world
  # Coastline
  tm_shape(coastline) +
  tm_lines() +
  # Rivers
  tm_shape(rivers) +
  tm_lines(lwd = 0.15) +
  # Lakes
  tm_shape(lakes) +
  tm_fill() +
  # Places
  tm_shape(places) +
  tm_symbols() +
  tm_text("NAME")

fancy_map

# It takes an inexplicably long time to render this map with Quarto, so I save
# it as a standalone HTML file, then show it in an ifram instead
tmap_save(fancy_map, "middle-earth.html", selfcontained = TRUE)


# <div class="ratio ratio-4x3">
# <iframe src="middle-earth.html" title="Interactive map of Middle Earth" allowfullscreen></iframe>
# </div>
