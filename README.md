# ios-mapkit-scale-bar
Simple easy-to-read scale bar for MapView.  Text font, scale bar length and thickness are configurable.

  * Add the ScaleBarView XIB to the storyboard for the map, at the required location
  * In the storyboard, set the background of the XIB to be clear (else it will have a white background)
  * Create an outlet for the ScaleBarView, in the map view
  ```
  @IBOutlet weak var scaleBarView: ScaleBarView!
  ```
  ```
  * create variable to remember the previous span value
    var prevSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.00001, longitudeDelta: 0.00001)
  ```
  * In the map view in viewDidLoad(), pass the map view object to scaleBarView
  ```
    override func viewDidLoad() {
        
        super.viewDidLoad()
                
        // Pass this mapView to the map scale bar
        scaleBarView.mapView = self.myMapView
  ```
  * In the method that detects changes to the map view region, call setNeedsLayout() when the zoom level has changed significantly - for example when the span changes by more than 2%
  ```
      func mapView(_ mapView: MKMapView, regionDidChangeAnimated: Bool) {
  
        // Update scale bar - if span changes by more than 2%
        // Note: This can sometimes happen when panning (at broader scale) without zooming
        let rect = mapView.visibleMapRect
        let newRegion = MKCoordinateRegion(rect)
        let newSpan = newRegion.span
        if fabs(prevSpan.longitudeDelta-newSpan.longitudeDelta)/prevSpan.longitudeDelta > 0.02
            || fabs(prevSpan.latitudeDelta-newSpan.latitudeDelta)/prevSpan.latitudeDelta > 0.02 {
            prevSpan = newSpan
            scaleBarView.setNeedsLayout()
        }
        
  ```
