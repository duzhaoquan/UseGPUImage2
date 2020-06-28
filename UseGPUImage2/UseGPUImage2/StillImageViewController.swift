//
//  StillImageViewController.swift
//  UseGPUImage2
//
//  Created by dzq_mac on 2020/6/28.
//  Copyright © 2020 dzq_mac. All rights reserved.
//

import UIKit
import GPUImage

class StillImageViewController: UIViewController {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        imageView.image = UIImage(contentsOfFile: Bundle.main.path(forResource: "hulu", ofType: "jpg")!)
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    var slider: UISlider = {
        
        let slider = UISlider(frame: CGRect(x: 20, y: SCREEN_HEIGHT - 30, width: SCREEN_WIDTH - 40, height: 20))
        return slider
    }()
    var filter:BasicOperation!
    var pictureInput : PictureInput!
    var filterModel:FilterModel = FilterModel(name: "BrightnessAdjustment 亮度",
                filterType: .basicOperation,
                range: (-1.0, 1.0, 0.0),
                initCallback: {BrightnessAdjustment()},
                valueChangedCallback: nil)
    let renderView = RenderView(frame:CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 85))
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "图片滤镜"
        view.backgroundColor = .white
        view.addSubview(imageView)
        view.addSubview(renderView)
        renderView.backgroundColor = .white
        renderView.isHidden = true
        view.addSubview(slider)
        slider.isHidden = true
        slider.addTarget(self, action: #selector(sliderValueChanged(slider:)), for: .valueChanged)
        pictureInput = PictureInput(image: imageView.image!)
        
        let filterButton = UIButton(frame: CGRect(x: 90, y: UIScreen.main.bounds.height - 80, width: 150, height: 40))
        filterButton.setTitle("选择滤镜", for: UIControl.State.normal)
        filterButton.center.x = view.center.x
        filterButton.backgroundColor = .gray
        filterButton.addTarget(self, action: #selector(ChoseFilters(btn:)), for: .touchUpInside)
        view.addSubview(filterButton)

    }

    @objc func ChoseFilters(btn:UIButton) {
        imageView.isHidden = true
        renderView.isHidden = false
        
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
        
        pictureInput.removeAllTargets()
        self.filter?.removeAllTargets()
        
        switch filterModel.filterType! {
            
        case .imageGenerators:
           imageView.image = imageView.image
        case .basicOperation:
            if let actualFilter = filterObject as? BasicOperation {
                self.filter = actualFilter
                pictureInput --> filter --> renderView
            }
            
        case .operationGroup:
            if let actualFilter = filterObject as? OperationGroup {
                pictureInput --> actualFilter --> renderView
            }
            
        case .blend:
            if let actualFilter = filterObject as? BasicOperation {
                self.filter = actualFilter
                let blendImgae = PictureInput(image: flowerImage)
                blendImgae --> actualFilter
                pictureInput --> filter --> renderView
                blendImgae.processImage()
                
            }
            
        case .custom:
            
            filterModel.customCallback!(pictureInput, filterObject, renderView)
            filter = filterObject as? BasicOperation
        }
        
        pictureInput.processImage()
        
        self.sliderValueChanged(slider: slider)
    }
    
    @objc func sliderValueChanged(slider: UISlider) {
        
        if let actualCallback = filterModel.valueChangedCallback {
            actualCallback(filter, slider.value)
            slider.isHidden = false
        } else {
            slider.isHidden = true
        }
        
        if filterModel.filterType! != .imageGenerators {
            pictureInput.processImage()
        }
    }
    func filteringImage() {
        
        // 创建一个BrightnessAdjustment颜色处理滤镜
        let brightnessAdjustment = BrightnessAdjustment()
        brightnessAdjustment.brightness = 0.2
        
        // 创建一个ExposureAdjustment颜色处理滤镜
        let exposureAdjustment = ExposureAdjustment()
        exposureAdjustment.exposure = 0.5
        
        // 1.使用GPUImage对UIImage的扩展方法进行滤镜处理
        var filteredImage: UIImage
        
        // 1.1单一滤镜
        filteredImage = imageView.image!.filterWithOperation(brightnessAdjustment)
        
        // 1.2多个滤镜叠加
        filteredImage = imageView.image!.filterWithPipeline { (input, output) in
            input --> brightnessAdjustment --> exposureAdjustment --> output
        }
        
        // 不建议的
        imageView.image = filteredImage
        
        // 2.使用管道处理
        
        // 创建图片输入
        let pictureInput = PictureInput(image: imageView.image!)
        // 创建图片输出
        let pictureOutput = PictureOutput()
        // 给闭包赋值
        pictureOutput.imageAvailableCallback = { image in
            // 这里的image是处理完的数据，UIImage类型
        }
        // 绑定处理链
        pictureInput --> brightnessAdjustment --> exposureAdjustment --> pictureOutput
        // 开始处理 synchronously: true 同步执行 false 异步执行，处理完毕后会调用imageAvailableCallback这个闭包
        pictureInput.processImage(synchronously: true)
    }
    
}
