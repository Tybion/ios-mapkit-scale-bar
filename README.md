# ios-mapkit-scale-bar
Simple easy-to-read scale bar for MapView.  Text font, scale bar length and thickness are configurable.

  * Add the ScaleBarView XIB to the storyboard for the map, at the required location
  * In the storyboard, set the background of the XIB to be transparent (else it will have a white background)
  * Create an outlet for the ScaleBarView, in the Map activity
  ```
  @IBOutlet weak var scaleBarView: ScaleBarView!
  ```
