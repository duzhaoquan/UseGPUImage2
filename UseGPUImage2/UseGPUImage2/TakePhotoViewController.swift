//
//  TakePhotoViewController.swift
//  UseGPUImage2
//
//  Created by dzq_mac on 2020/6/28.
//  Copyright © 2020 dzq_mac. All rights reserved.
//

import UIKit
import GPUImage
import AVFoundation

class TakePhotoViewController: UIViewController {
    
    var filterModel:FilterModel = FilterModel(name: "BrightnessAdjustment 亮度",
                                              filterType: .basicOperation,
                                              range: (-1.0, 1.0, 0.5),
                                              initCallback: {BrightnessAdjustment()},
                                              valueChangedCallback: { (filter, value) in
                                                (filter as! BrightnessAdjustment).brightness = value
    })
    var picture:PictureInput!
    var filter:BasicOperation!
    var camera: Camera!
    var movieOutput:MovieOutput? = nil
    var movie: MovieInput!
    var renderView: RenderView!
    
    var takeButton : UIButton!
    var filterButton : UIButton!
    var reTakeButton : UIButton!
    var slider: UISlider = {
        
        let slider = UISlider(frame: CGRect(x: 20, y: SCREEN_HEIGHT - 30, width: SCREEN_WIDTH - 40, height: 20))
        return slider
    }()
    func creaatRenderView() -> RenderView{
        let renderView = RenderView(frame:CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 100))
        return renderView
    }
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 80))
        imageView.image = UIImage(contentsOfFile: Bundle.main.path(forResource: "hulu", ofType: "jpg")!)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .purple
        imageView.isHidden = true
        return imageView
    }()
    @objc func ChoseFilters(btn:UIButton) {
        
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
    func setupFilterChain(filterModel:FilterModel) {
        title = filterModel.name
        //           pictureInput = PictureInput(image: MaYuImage)
        slider.minimumValue = filterModel.range?.0 ?? 0
        slider.maximumValue = filterModel.range?.1 ?? 0
        slider.value = filterModel.range?.2 ?? 0
        let filterObject = filterModel.initCallback()
        
        camera.removeAllTargets()
        filter.removeAllTargets()
        renderView.sources.removeAtIndex(0)
        switch filterModel.filterType! {
            
        case .imageGenerators:
            filterObject as! ImageSource --> renderView
            
        case .basicOperation:
            if let actualFilter = filterObject as? BasicOperation {
                filter = actualFilter
                camera --> actualFilter --> renderView
                //                   pictureInput.processImage()
            }
            
        case .operationGroup:
            if let actualFilter = filterObject as? OperationGroup {
                camera --> actualFilter --> renderView
            }
            
        case .blend:
            if let actualFilter = filterObject as? BasicOperation {
                filter = actualFilter
                let blendImgae = PictureInput(image: flowerImage)
                blendImgae --> actualFilter
                camera --> actualFilter --> renderView
                blendImgae.processImage()
                
            }
            
        case .custom:
            filterModel.customCallback!(camera, filterObject, renderView)
            filter = filterObject as? BasicOperation
            
        }
        
        
        
        self.sliderValueChanged(slider: slider)
    }
    
    @objc func sliderValueChanged(slider: UISlider) {
        
        //           print("slider value: \(slider.value)")
        
        if let actualCallback = filterModel.valueChangedCallback {
            actualCallback(filter, slider.value)
            slider.isHidden = false
        } else {
            slider.isHidden = true
        }
        
        if filterModel.filterType! != .imageGenerators {
            
        }
    }
  
    //拍摄
    @objc func takePhoto() {
        takeButton.isHidden = true
        reTakeButton.isHidden = false
        
        
        // 设置保存路径
        guard let outputPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }

        let originalPath = outputPath + "/originalImage.png"
        print("path: \(originalPath)")
        let originalURL = URL(fileURLWithPath: originalPath)

        let filteredPath = outputPath + "/filteredImage.png"
        print("path: \(filteredPath)")

        let filteredlURL = URL(fileURLWithPath: filteredPath)
        // 保存相机捕捉到的图片
        self.camera.saveNextFrameToURL(originalURL, format: .png)

        // 保存滤镜后的图片
        self.filter.saveNextFrameToURL(filteredlURL, format: .png)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100)) {
            self.renderView.isHidden = true
            self.imageView.isHidden = false
            self.imageView.image = UIImage(contentsOfFile: filteredPath)
        }
        
//        // 如果需要处理回调，有下面两种写法
//        let dataOutput = PictureOutput()
//        dataOutput.encodedImageFormat = .png
//        dataOutput.encodedImageAvailableCallback = {imageData in
//            // 这里的imageData是截取到的数据，Data类型
//        }
//        self.camera --> dataOutput
//
//        let imageOutput = PictureOutput()
//        imageOutput.encodedImageFormat = .png
//        imageOutput.imageAvailableCallback = {image in
//            // 这里的image是截取到的数据，UIImage类型
//            self.imageView.image = image
//        }
//
//        self.camera --> imageOutput
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "拍照滤镜"
        view.backgroundColor = .white
        
        slider.addTarget(self, action: #selector(sliderValueChanged(slider:)), for: .valueChanged)
        self.renderView = creaatRenderView()
        view.addSubview(renderView)
        view.addSubview(imageView)
        view.addSubview(slider)
        slider.isHidden = true
        
        if let fi = filterModel.initCallback() as? BasicOperation{
            filter = fi
        }else{
            filter = BrightnessAdjustment()
        
        }
        
        takeButton = UIButton(frame: CGRect(x: 20, y: UIScreen.main.bounds.height - 100, width:60, height: 60))
        takeButton.setTitle("拍摄", for: UIControl.State.normal)
        takeButton.backgroundColor = .gray
        takeButton.center.x = self.view.center.x
        takeButton.layer.cornerRadius = 30
        takeButton.addTarget(self, action: #selector(takePhoto), for: UIControl.Event.touchUpInside)
        view.addSubview(takeButton)
        
        filterButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 100, y: UIScreen.main.bounds.height - 90, width: 80, height: 40))
        filterButton.setTitle("选择滤镜", for: UIControl.State.normal)
        filterButton.backgroundColor = .gray
        filterButton.addTarget(self, action: #selector(ChoseFilters), for: .touchUpInside)
        view.addSubview(filterButton)
        
        reTakeButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 100, y: UIScreen.main.bounds.height - 90, width: 80, height: 40))
        reTakeButton.setTitle("重新拍摄", for: UIControl.State.normal)
        reTakeButton.backgroundColor = .gray
        reTakeButton.center.x = self.view.center.x
        reTakeButton.addTarget(self, action: #selector(retake), for: UIControl.Event.touchUpInside)
        view.addSubview(reTakeButton)
        
        reTakeButton.isHidden = true
        
        cameraFiltering()
    }
     @objc func retake() {
        takeButton.isHidden = false
        reTakeButton.isHidden = true
        renderView.isHidden = false
        imageView.isHidden = true
    }
    
    func cameraFiltering() {
        
        // Camera的构造函数是可抛出错误的
        do {
            camera = try Camera(sessionPreset: AVCaptureSession.Preset.hd1280x720,
                                cameraDevice: nil,
                                location: .backFacing,
                                captureAsYUV: true)
            
        } catch {
            print(error)
            return
        }
        // 绑定处理链
        camera --> renderView
        
        // 开始捕捉数据
        self.camera.startCapture()
        // 结束捕捉数据
        // camera.stopCapture()
        
    }
    
    
    
    
}
