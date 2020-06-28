//
//  VideoViewController.swift
//  UseGPUImage2
//
//  Created by dzq_mac on 2020/6/23.
//  Copyright © 2020 dzq_mac. All rights reserved.
//

import UIKit
import GPUImage
import AVFoundation
class VideoViewController: UIViewController {

    var filterModel:FilterModel = FilterModel(name: "BrightnessAdjustment 亮度",
                filterType: .basicOperation,
                range: (-1.0, 1.0, 0.0),
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
    var slider: UISlider = {
        
        let slider = UISlider(frame: CGRect(x: 8, y: SCREEN_HEIGHT - 30, width: SCREEN_WIDTH - 18, height: 20))
        return slider
    }()
    func creaatRenderView() -> RenderView{
        let renderView = RenderView(frame:CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 50))
        let button = UIButton(frame: CGRect(x: 20, y: UIScreen.main.bounds.height - 100, width:80, height: 40))
        button.setTitle("开始录制", for: UIControl.State.normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(startVideo(btn:)), for: UIControl.Event.touchUpInside)
        renderView.addSubview(button)
        
        let filterButton = UIButton(frame: CGRect(x: 130, y: UIScreen.main.bounds.height - 100, width: 80, height: 40))
        filterButton.setTitle("选择滤镜", for: UIControl.State.normal)
        filterButton.backgroundColor = .gray
        filterButton.center.x = self.view.center.x
        filterButton.addTarget(self, action: #selector(ChoseFilters), for: .touchUpInside)
        renderView.addSubview(filterButton)
        
        let playButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 100, y: UIScreen.main.bounds.height - 100, width: 80, height: 40))
        playButton.setTitle("播放视频", for: UIControl.State.normal)
        playButton.backgroundColor = .gray
        playButton.addTarget(self, action: #selector(playMovie(btn:)), for: UIControl.Event.touchUpInside)
        renderView.addSubview(playButton)
        
        return renderView
    }
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
           } else {
               slider.isHidden = true
           }
           
           if filterModel.filterType! != .imageGenerators {
            
           }
       }
    //播放
    @objc func playMovie(btn:UIButton){
        
        let playVc = PlayMoviewViewController()
        self.navigationController?.pushViewController(playVc, animated: true)
        
//        btn.isSelected = !btn.isSelected
//        if btn.isSelected {
//
//            btn.setTitle("停止", for: UIControl.State.normal)
//            
//            let documentsDir = try! FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
//            let fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
//            movie = try? MovieInput(url:fileURL, playAtActualSpeed:true)
//            
//
//            let renderView1 = RenderView(frame: view.bounds)
//            view.addSubview(renderView1)
//            movie --> renderView1
//            movie.runBenchmark = true
//            movie.start()
//        
//        }else{
//            btn.setTitle("播放", for: UIControl.State.normal)
//            movie.cancel()
//        }
    }
    //拍摄
    @objc func startVideo(btn:UIButton){
        btn.isSelected = !btn.isSelected
        if btn.isSelected {
            btn.setTitle("stop", for: UIControl.State.normal)
            do {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
                print(documentsPath)
                let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
                let fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
                
                do {
                    try FileManager.default.removeItem(at:fileURL)
                } catch {
                    print("error")
                }
                movieOutput = try MovieOutput(URL:fileURL, size:Size(width:480, height:640), liveVideo:true)
                camera.audioEncodingTarget = movieOutput
                camera.removeAllTargets()
                camera --> filter --> movieOutput!
                movieOutput!.startRecording()
                
            } catch {
                fatalError("Couldn't initialize movie, error: \(error)")
            }
        }else{
            btn.setTitle("start", for: UIControl.State.normal)
            
            movieOutput?.finishRecording{
                self.camera.audioEncodingTarget = nil
                self.movieOutput = nil
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "拍摄视频"
        view.backgroundColor = .white
        
        slider.addTarget(self, action: #selector(sliderValueChanged(slider:)), for: .valueChanged)
        self.renderView = creaatRenderView()
        view.addSubview(renderView)
        view.addSubview(slider)
        slider.isHidden = true
        
        if let fi = filterModel.initCallback() as? BasicOperation{
            filter = fi
        }else{
            filter = BrightnessAdjustment()
        }
        cameraFiltering()
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
