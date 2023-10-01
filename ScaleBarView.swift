//
//  ScaleBarView.swift
//  Mapa turystyczna
//
//  Created by Roman Barzyczak on 21.10.2016.
//  Copyright © 2016 Mapa Turystyczna. All rights reserved.
//
import UIKit
import MapKit

// ********************************************************************
// https://github.com/yoman07/ios-google-maps-scale-bar

@IBDesignable
class ScaleBarView: UIView {
    
    private static let defaultWidth:CGFloat = 200.0
    
    weak var mapView: MKMapView?            // set from outside of the class
    
    @IBOutlet weak var scaleBarConstant: NSLayoutConstraint!
    @IBOutlet weak var distanceLabel: UILabel!
    
    // Shows how to add the XIB to the main storyboard ..
    // https://medium.com/zenchef-tech-and-product/
    // how-to-visualize-reusable-xibs-in-storyboards-using-ibdesignable-c0488c7f525d

    var contentView: UIView?
    @IBInspectable var nibName: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    func xibSetup() {
        guard let view = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask =
            [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
    }
    
    func loadViewFromNib() -> UIView? {
        guard let nibName = nibName else { return nil }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(
            withOwner: self,
            options: nil).first as? UIView
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }
    
    // ********************************************************************
    // https://github.com/yoman07/ios-google-maps-scale-bar ..
    // *************************************************
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        guard let mapView = self.mapView
            else {
                return
        }
        
        let screenWidth = mapView.frame.width       // width of mapView (pixels?)
        let barWidth = self.frame.width             // width of scale bar (pixels?)
        
        // https://medium.com/@dmytrobabych/getting-actual-rotation-and-zoom-level-for-mapkit-mkmapview-e7f03f430aa9
        //  mapView.region is bigger than iPhone screen when rotated.
        // it is the ns-ew aligned bounding box of the rotated map
        
        // Get longitudes of west and east side of screen, at base of map.
        let rect = mapView.visibleMapRect       // rectangle of mapView
        let region = MKCoordinateRegion(rect)   // region for mapView
        
        var screenDistance: CLLocationDistance      // metres
        if mapView.camera.heading == 0 {
            // simple, usual case
            let baseLeft = region.baseLeft()
            let baseRight = region.baseRight()
            screenDistance = baseLeft.distance(from: baseRight)     // METRES
        } else {
            // for when map has been rotated within the screen
            screenDistance = spanAdjustedForRotation(
                            mapView.camera.heading, mapView, region)    // METRES
        }
        
        let scaleBarDistance: CGFloat = barWidth/screenWidth * screenDistance
        let roundedDistance = scaleBarDistance.roundAsDistance()
        
        // App was crashing with failure in [NSLayoutConstraint _setSymbolicConstant:constant:]
        if mapView.zoomLevel < 3.0 {
            distanceLabel.text = ""
            return
        }
        
        // CRASH: Sep 2019 - NSLayoutConstraint constant is not finite! That's illegal.
        //  - when setting scaleBarConstant.constant, below
        // screenDistance might be zero => divide by zero
        if screenDistance == 0.0 {
            distanceLabel.text = ""
            return
        }

        // Now adjust the scale bar length
        self.scaleBarConstant.constant = scaledBarWidth(
                                    screenDistance, screenWidth, roundedDistance)
        // And the text - eg. 100 km
        distanceLabel.text = roundedDistanceFormatted(roundedDistance)
    }
    
    // *************************************************************************
    private func spanAdjustedForRotation(_ cameraHeading: CLLocationDirection,
                                         _ mapView: MKMapView,
                                         _ region: MKCoordinateRegion) -> Double {
        // Keep heading between -90 and 90
        // (could even keep it between 0 and 90 - all other cases are equivalent)
        var heading = cameraHeading
        if heading > 270 {
            heading = 360 - heading
        } else if heading > 90 {
            heading = fabs(heading - 180)
        }
        // work out the region's span if the map was NOT rotated ..
        let radians = Double.pi * heading / 180 // map rotation in radians
        let width = Double(mapView.frame.width)
        let height = Double(mapView.frame.height)
        let regionWidth = region.baseLeft().distance(from: region.baseRight())   // METRES
        let spanStraight = width * regionWidth /
                (width * cos(radians) + height * sin(radians))
        return spanStraight
    }
    // *************************************************************************

    private func roundedDistanceFormatted(_ roundedDistance: Int) -> String {
        return formatDistance(distance: roundedDistance)
    }
    
    private func scaledBarWidth(_ screenDistance: CGFloat, _ screenWidth: CGFloat,
                                        _ roundedDistance: Int) -> CGFloat {
        let scaleRatio = CGFloat(roundedDistance) / screenDistance
        let scaleBarWidth =  screenWidth * scaleRatio
        return CGFloat(scaleBarWidth)
    }
    
    private func formatDistance(distance: Int) -> String {
        if distance < 1000 {
            return String(format: "%d m", distance)
        } else {
            return String(format: "%d km", distance/1000)
        }
    }
}

extension CLLocationCoordinate2D {
    // CLLocation has distance(), but not CLLocation2D
    func distance(from coordinate: CLLocationCoordinate2D) -> CGFloat {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return CGFloat(location1.distance(from: location2))
    }
}

extension CGFloat {
    func roundAsDistance() -> Int {
        var roundedDistance = 1
        var i = 0;
        while (1 + pow(CGFloat(i % 3), 2)) * pow(10, floor(CGFloat(i / 3))) < self {
            roundedDistance =  Int(((1 + pow(CGFloat(i % 3), 2)) * pow(10, floor(CGFloat(i / 3)))))
            i+=1
        }
        return roundedDistance
    }
}
