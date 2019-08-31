//
//  ScaleBarView.swift
//
//  Code from sources below has been re-developed and tested by David Collins, Australia, 2019,
//  for use with MapKit. Development environment: Xcode 10.3, Swift 5.
//
//  Based on code created by Roman Barzyczak on 21.10.2016.
//  Copyright © 2016 Mapa Turystyczna. All rights reserved.
//  https://github.com/yoman07/ios-google-maps-scale-bar

// Also based on code by Adrien Cognée Jan 5, 2017
// How to visualize reusable xibs in storyboards using IBDesignable
// https://medium.com/zenchef-tech-and-product/how-to-visualize-reusable-xibs-in-storyboards-using-ibdesignable-c0488c7f525d

import UIKit
import MapKit

// ********************************************************************
@IBDesignable
class ScaleBarView: UIView {
    
    private static let defaultWidth:CGFloat = 200.0
    
    weak var mapView: MKMapView?            // set from outside of the class
    
    @IBOutlet weak var scaleBarConstant: NSLayoutConstraint!
    @IBOutlet weak var distanceLabel: UILabel!
    
    // Shows how to add the XIB to the main storyboard ..
    // How to visualize reusable xibs in storyboards using IBDesignable
    // https://medium.com/zenchef-tech-and-product/how-to-visualize-reusable-xibs-in-storyboards-using-ibdesignable-c0488c7f525d

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
    
    // use .xib with same name
    fileprivate func loadViewFromNib1() -> UIView {
        
        let nibName = String(describing: type(of: self))
        if let views = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil) {
            if let view = views[0] as? UIView {
                return view
            }
        }
        return UIView()
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
        
        //let projection = mapView.projection
        let screenWidth = mapView.frame.width
        let barWidth = self.frame.width
        
        // Get longitudes of west and east side of screen, at base of map.
        let rect = mapView.visibleMapRect
        let region = MKCoordinateRegion(rect)
        
        // Assuming the scale bar will be towards the bottom of the map
        // If scale bar will be near the top, better to use topLeft and topRight
        let baseLeft = region.baseLeft()
        let baseRight = region.baseRight()
        
        let screenDistance = baseLeft.distance(from: baseRight)
        let scaleDistance = barWidth/screenWidth * screenDistance
        let roundedDistance = scaleDistance.roundAsDistance()
        
        // App was crashing with failure in [NSLayoutConstraint _setSymbolicConstant:constant:]
        // At broad zoom levels, scale changes from top to bottom of map, so scale bar value is not meaningful
        if mapView.zoomLevel < 3.0 {
            distanceLabel.text = ""
            return
        }

        // Now adjust the scale bar length
        self.scaleBarConstant.constant = scaledBarWidth(
                                    screenDistance, screenWidth,roundedDistance)
        // And the text - eg. 100 km
        distanceLabel.text = roundedDistanceFormatted(roundedDistance)
    }
    
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

// ******************************
extension MKCoordinateRegion {

    func baseLeft() -> CLLocationCoordinate2D {
        
        let baseMap = center.latitude - span.latitudeDelta/2.0
        let leftMap = center.longitude - span.longitudeDelta/2.0
        return CLLocationCoordinate2D(latitude: baseMap, longitude: leftMap)
    }

    func baseRight() -> CLLocationCoordinate2D {
        
        let baseMap = center.latitude - span.latitudeDelta/2.0
        let rightMap = center.longitude + span.longitudeDelta/2.0
        return CLLocationCoordinate2D(latitude: baseMap, longitude: rightMap)
    }
}
