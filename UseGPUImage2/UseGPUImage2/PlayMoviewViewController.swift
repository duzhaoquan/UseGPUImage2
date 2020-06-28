//
//  PlayMoviewViewController.swift
//  UseGPUImage2
//
//  Created by dzq_mac on 2020/6/23.
//  Copyright © 2020 dzq_mac. All rights reserved.
//

import UIKit
import GPUImage

class PlayMoviewViewController: UIViewController {

    var filter:BasicOperation = BrightnessAdjustment()
    var renderView: RenderView!
    var filterModel:FilterModel = FilterModel(name: "BrightnessAdjustment 亮度",
                filterType: .basicOperation,
                range: (-1.0, 1.0, 0.0),
                initCallback: {BrightnessAdjustment()},
                valueChangedCallback: { (filter, value) in
                    (filter as! BrightnessAdjustment).brightness = value
    })
    var movie: MovieInput! = {
        let documentsDir = try! FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
        let fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
        let movie = try? MovieInput(url:fileURL, playAtActualSpeed:true)
        return movie
        
    }()
    var slider: UISlider = {
        
        let slider = UISlider(frame: CGRect(x: 8, y: SCREEN_HEIGHT - 30, width: SCREEN_WIDTH - 18, height: 20))
        return slider
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "播放视频添加滤镜"
        view.backgroundColor = .white
        addbutton()
        
        slider.addTarget(self, action: #selector(sliderValueChanged(slider:)), for: .valueChanged)
        view.addSubview(slider)
        slider.isHidden = true
    }
    @objc func buttonClick(btn:UIButton){
        if btn.tag == 101 {
            
            
        }else if btn.tag == 102{
            playMovie(btn: btn)
        }else if btn.tag == 103{
            
            let fvc = FilterListTableViewController()
            fvc.filterBlock =  {  [weak self] filterModel in
                guard let `self` = self else {
                    return
                }
                self.filterModel = filterModel
                
                self.setupFilterChain(filterModel: filterModel)
                
            }
            self.navigationController?.pushViewController(fvc, animated: true)
            
        }
    }
    
     func setupFilterChain(filterModel:FilterModel) {
            title = filterModel.name
            //           pictureInput = PictureInput(image: MaYuImage)
            slider.minimumValue = filterModel.range?.0 ?? 0
            slider.maximumValue = filterModel.range?.1 ?? 0
            slider.value = filterModel.range?.2 ?? 0
            let filterObject = filterModel.initCallback()
            
            movie.removeAllTargets()
            filter.removeAllTargets()
            renderView.sources.removeAtIndex(0)
            switch filterModel.filterType! {
                
            case .imageGenerators:
                filterObject as! ImageSource --> renderView
                
            case .basicOperation:
                if let actualFilter = filterObject as? BasicOperation {
                    filter = actualFilter
                    movie --> actualFilter --> renderView
                    //                   pictureInput.processImage()
                }
                
            case .operationGroup:
                if let actualFilter = filterObject as? OperationGroup {
                    movie --> actualFilter --> renderView
                }
                
            case .blend:
                if let actualFilter = filterObject as? BasicOperation {
                    filter = actualFilter
                    let blendImgae = PictureInput(image: flowerImage)
                    blendImgae --> actualFilter
                    movie --> actualFilter --> renderView
                    blendImgae.processImage()
                    
                }
                
            case .custom:
                filterModel.customCallback!(movie, filterObject, renderView)
                filter = (filterObject as? BasicOperation)!
            }
            
            
            
            self.sliderValueChanged(slider: slider)
        }
           
           @objc func sliderValueChanged(slider: UISlider) {
               
    //           print("slider value: \(slider.value)")
               
               if let actualCallback = filterModel.valueChangedCallback {
                   actualCallback(filter, slider.value)
               } else {
                   slider.isHidden = true
               }
               
               if filterModel.filterType! != .imageGenerators {
                
               }
           }
    func addbutton() {
        let buttonX = UIButton(frame: CGRect.zero)
        buttonX.tag = 101
        buttonX.setTitle("选视频", for: UIControl.State.normal)
        buttonX.addTarget(self, action: #selector(buttonClick(btn:)), for: UIControl.Event.touchUpInside)
        buttonX.backgroundColor = UIColor.gray
        let buttonY = UIButton(frame: CGRect.zero)
        
        buttonY.tag = 102
        buttonY.setTitle("播放", for: UIControl.State.normal)
        buttonY.addTarget(self, action: #selector(buttonClick(btn:)), for: UIControl.Event.touchUpInside)
        buttonY.backgroundColor = UIColor.gray
        
        let buttonZ = UIButton(frame: CGRect.zero)
        buttonZ.tag = 103
        buttonZ.setTitle("选滤镜", for: UIControl.State.normal)
        buttonZ.addTarget(self, action: #selector(buttonClick(btn:)), for: UIControl.Event.touchUpInside)
        buttonZ.backgroundColor = UIColor.gray
        
        view.addSubview(buttonX)
        view.addSubview(buttonY)
        view.addSubview(buttonZ)
        
        buttonX.translatesAutoresizingMaskIntoConstraints = false
        buttonY.translatesAutoresizingMaskIntoConstraints = false
        buttonZ.translatesAutoresizingMaskIntoConstraints = false

        buttonY.widthAnchor.constraint(equalTo: buttonX.widthAnchor).isActive = true
        buttonZ.widthAnchor.constraint(equalTo: buttonX.widthAnchor).isActive = true

        buttonX.leftAnchor.constraint(equalTo: view.leftAnchor,constant: 20).isActive = true
        buttonX.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5).isActive = true
        buttonX.heightAnchor.constraint(equalToConstant: 60).isActive = true

        buttonY.leftAnchor.constraint(equalTo: buttonX.rightAnchor,constant: 10).isActive = true
        buttonY.topAnchor.constraint(equalTo: buttonX.topAnchor).isActive = true
        buttonY.bottomAnchor.constraint(equalTo: buttonX.bottomAnchor).isActive = true

        buttonZ.leftAnchor.constraint(equalTo: buttonY.rightAnchor,constant: 10).isActive = true
        buttonZ.topAnchor.constraint(equalTo: buttonX.topAnchor).isActive = true
        buttonZ.bottomAnchor.constraint(equalTo: buttonX.bottomAnchor).isActive = true
        buttonZ.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -20).isActive = true
    }

    //播放
    @objc func playMovie(btn:UIButton){
        btn.isSelected = !btn.isSelected
        if btn.isSelected {
            
            btn.setTitle("stop", for: UIControl.State.normal)
            if (movie == nil) {
                
                filter = SaturationAdjustment()
                movie --> filter --> renderView
                movie.start()
            }else{
                movie --> filter
            }
            
//            movie.runBenchmark = true
//
            
            
            
        }else{
            btn.setTitle("play", for: UIControl.State.normal)
//            movie.cancel()
            movie.removeAllTargets()
//            filter.removeAllTargets()
        }
    }
    

}
