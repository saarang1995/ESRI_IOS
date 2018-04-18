//
//  ViewController.swift
//  Replica and Sync
//
//  Created by Saarang on 4/14/18.
//  Copyright © 2018 Saarang. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSLayerDelegate{

    @IBOutlet weak var mapView: AGSMapView!
    let featureServiceUrl="https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer/0"
    let featureServiceSyncUrl="https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/SaveTheBaySync/FeatureServer"

    var geodatabaseTask:AGSGDBSyncTask!
    var geodatabaseJob:AGSCancellable!
    var generateParameters:AGSGDBGenerateParameters!
    var geodatabaseFeatureTable:AGSGDBFeatureTable!
    var geodatabaseFeatureTableLayer:AGSFeatureTableLayer!
    var gdbfeaturetable:AGSGDBFeatureTable!
    var extent:AGSEnvelope!
    override func viewDidLoad() {
        super.viewDidLoad()
       // loadBaseMap();
        //Generate Parameters:
        self.extent=AGSEnvelope(xmin: -180, ymin: -38.76923108, xmax: 180, ymax: 90, spatialReference: AGSSpatialReference(wkid: 4326))
        self.generateParameters=AGSGDBGenerateParameters(extent: extent, layerIDs: [0])
        self.generateParameters.syncModel = .perLayer
        self.generateParameters.outSpatialReference=AGSSpatialReference(wkid: 4326)
        
        run();
       // testingUsingOffline();
        
    }
    
    private func loadBaseMap(){
        let url = URL(string: "https://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer")
        let tiledLayer=AGSTiledMapServiceLayer(url: url)
        self.mapView.addMapLayer(tiledLayer, withName: "Basemap Tiled Layer")
    }
    
    
    private func DownloadData(){
        
        let featureLayer=AGSFeatureLayer(url: URL(string: featureServiceUrl), mode: .onDemand)
       // self.mapView.addMapLayer(featureLayer)
        featureLayer?.delegate=self
        
    }
   
    private func offlineLoadingAndSyncing(path:String) throws ->AGSGDBGeodatabase{
       return try AGSGDBGeodatabase(path: path)
        
    }
        
    
    private func run() {
        //Geodatabase Task:
         self.geodatabaseTask=AGSGDBSyncTask(url: URL(string: featureServiceSyncUrl))
        self.geodatabaseTask.loadCompletion={ [weak self](error:Error!) -> Void in
            if(error==nil)
            {self?.geodatabaseJob=self?.geodatabaseTask.generateGeodatabase(with: self?.generateParameters, downloadFolderPath: "/Users/saarang/Cases/2018/April/02099102/data", useExisting: false, status: { (status:AGSResumableTaskJobStatus, userInfo:[AnyHashable:Any]?) -> Void in
                    print("status: \(status.rawValue)")},
                    completion: { [weak self](geodatabase:AGSGDBGeodatabase!, error:Error!) -> Void in
                    if(error==nil){
                        var layers:NSArray
                        layers=geodatabase?.featureTables()! as! NSArray
                        for lyr in layers{
                            self?.gdbfeaturetable=lyr as! AGSGDBFeatureTable
                            self?.geodatabaseFeatureTableLayer = AGSFeatureTableLayer(featureTable: self?.gdbfeaturetable)
                            self?.geodatabaseFeatureTableLayer.delegate = self
                            self?.mapView.addMapLayer(self?.geodatabaseFeatureTableLayer, withName:"\(self?.gdbfeaturetable.tableName())")

                            //Create a geometry
                            let point = AGSPoint(x: -120.732162, y: 35.172987, spatialReference: AGSSpatialReference(wkid: 4326))
                            
                            //Instantiate a new feature
                            let feature = AGSGDBFeature(table: self?.gdbfeaturetable)
                            
                            //Set the geometry
                            feature?.geometry = point
                            feature?.setAttribute("Saarang", forKey: "comments")
                            //Add the feature to the AGSGDBFeatureTable
                            do{
                                if let result=try self?.addfeature(feature: feature!,gdb:geodatabase!,gdbfeaturetable: (self?.gdbfeaturetable)!) as? Error{
                                    
                                }}catch let error as Error{
                                    print("error\(error.localizedDescription)")}} }}) } }
        
        }
    func addfeature(feature: AGSGDBFeature,gdb:AGSGDBGeodatabase,gdbfeaturetable:AGSGDBFeatureTable) throws
    {
        let success=try gdbfeaturetable.save(feature)// as? Bool
        print(feature.objectID)
        let syncParams = AGSGDBSyncParameters(geodatabase: gdb)
        //Synchronize the geodatabase (with parameters)
        self.geodatabaseTask.syncGeodatabase(gdb, params: syncParams!, status: { (status: AGSResumableTaskJobStatus,userInfo:Any? ) in
            print("Status : \(status)")},
                                             completion: { (editError: AGSGDBEditErrors!,error:Error! ) in
                                                if error != nil {
                                                    print("Error synchronizing geodatabase: \(error)")
                                                    
                                                }
                                                else {
                                                    print("Synchronization complete")}
                                                
        }
        )

    }
    
    private func testingUsingOffline()
    {
        
        let path="/Users/saarang/Cases/2018/April/02099102/data/_ags_dataEB14F0E14FF246DF84752C5D73CB6FC1.geodatabase"
        self.geodatabaseTask=AGSGDBSyncTask(url: URL(string: featureServiceSyncUrl))
        self.geodatabaseTask.loadCompletion={ [weak self](error:Error!) -> Void in
            if(error==nil)
            {
                do{
                    if var gdb=try self?.offlineLoadingAndSyncing(path:path) as? AGSGDBGeodatabase{print("Opening Geodatabase")
                        var layers:NSArray
                        layers=gdb.featureTables()! as! NSArray
                        for lyr in layers{
                            self?.gdbfeaturetable=lyr as! AGSGDBFeatureTable
                            self?.geodatabaseFeatureTableLayer = AGSFeatureTableLayer(featureTable: self?.gdbfeaturetable)
                            self?.geodatabaseFeatureTableLayer.delegate = self
                            self?.mapView.addMapLayer(self?.geodatabaseFeatureTableLayer, withName:"\(self?.gdbfeaturetable.tableName())")
                            
                            //Create a geometry
                            let point = AGSPoint(x: -120.732162, y: 35.172987, spatialReference: AGSSpatialReference(wkid: 4326))
                            
                            //Instantiate a new feature
                            let feature = AGSGDBFeature(table: self?.gdbfeaturetable)
                            
                            //Set the geometry
                            feature?.geometry = point
                            feature?.setAttribute("Saarang", forKey: "comments")
                            //Add the feature to the AGSGDBFeatureTable
                            do{
                                if let result=try self?.addfeature(feature: feature!,gdb:gdb,gdbfeaturetable: (self?.gdbfeaturetable)!) as? Error{
                                } }
                            catch let error as Error{
                                print("error\(error.localizedDescription)")}}
                    }
                    
                    
                    
                }catch let error as Error{print("Error while opening Geodatabase error message:\(error.localizedDescription)")}
            } }
        
    }
}

