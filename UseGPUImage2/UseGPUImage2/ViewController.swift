//
//  ViewController.swift
//  UseGPUImage2
//
//  Created by dzq_mac on 2020/6/17.
//  Copyright © 2020 dzq_mac. All rights reserved.
//

import UIKit
import AVFoundation
import GPUImage

class ViewController: UIViewController, CameraDelegate {
    func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
        
    }
    

    var picture:PictureInput!
    var filter:BasicOperation!
    var camera: Camera!
    var movieOutput:MovieOutput? = nil
    var movie: MovieInput!
    
    lazy var renderView: RenderView = {
        let renderView = RenderView(frame: view.bounds)
        let button = UIButton(frame: CGRect(x: 20, y: UIScreen.main.bounds.height - 50, width: 50, height: 40))
        button.setTitle("start video", for: UIControl.State.normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(startVideo(btn:)), for: UIControl.Event.touchUpInside)
        renderView.addSubview(button)
        
        let filterButton = UIButton(frame: CGRect(x: 90, y: UIScreen.main.bounds.height - 50, width: 150, height: 40))
        filterButton.setTitle("选择滤镜", for: UIControl.State.normal)
        filterButton.backgroundColor = .gray
        filterButton.addTarget(self, action: #selector(ChoseFilter), for: .touchUpInside)
        renderView.addSubview(filterButton)
        
        let playButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 70, y: UIScreen.main.bounds.height - 50, width: 50, height: 40))
        playButton.setTitle("play", for: UIControl.State.normal)
        playButton.backgroundColor = .gray
        playButton.addTarget(self, action: #selector(playMovie(btn:)), for: UIControl.Event.touchUpInside)
        renderView.addSubview(playButton)
        
        return renderView
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        imageView.image = UIImage(contentsOfFile: Bundle.main.path(forResource: "hulu", ofType: "jpg")!)
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    @objc func ChoseFilter(btn:UIButton) {
       
        let fvc = FilterListTableViewController()
        fvc.filterBlock =  {  [weak self] filter in
//            guard let `self` = self else {
//                return
//            }
//            self.filter = filter
//            
//            self.renderView.removeFromSuperview()
//            self.renderView = self.renderView(isVideo: btn.tag == 101 ? true : false)
//            
//            self.camera --> self.filter --> self.renderView
//            self.view.addSubview(self.renderView)
            
        }
        self.navigationController?.pushViewController(fvc, animated: true)
        
    }
    @objc func playMovie(btn:UIButton){
        btn.isSelected = !btn.isSelected
        if btn.isSelected {
            camera.stopCapture()
            btn.setTitle("stop", for: UIControl.State.normal)
            
            let documentsDir = try! FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            let fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
            movie = try? MovieInput(url:fileURL, playAtActualSpeed:true)

            let renderView1 = RenderView(frame: view.bounds)
            view.addSubview(renderView1)
            movie --> renderView1
            movie.runBenchmark = true
            movie.start()
            
        }else{
            btn.setTitle("play", for: UIControl.State.normal)
            movie.cancel()
        }
    }
    //
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
                    
                   }
                   movieOutput = try MovieOutput(URL:fileURL, size:Size(width:480, height:640), liveVideo:true)
                   camera.audioEncodingTarget = movieOutput
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
        
        self.view.backgroundColor = .white
        view.addSubview(imageView)
        addbutton()
        
    }
    
    /*
     
     */
    @objc func buttonClick(btn:UIButton){
        if btn.tag == 101 {
            let videoVC = VideoViewController()
            self.navigationController?.pushViewController(videoVC, animated: true)
            
        }else if btn.tag == 102{
            self.renderView.removeFromSuperview()
            self.renderView = renderView(isVideo: false)
            self.view.addSubview(self.renderView)
            self.cameraFiltering()
        }else if btn.tag == 103{
            filteringImage()
        }
    }
    func renderView(isVideo:Bool) ->RenderView  {
        
        let renderView = RenderView(frame: view.bounds)
        
        if isVideo {
            let button = UIButton(frame: CGRect(x: 20, y: UIScreen.main.bounds.height - 50, width: 50, height: 40))
            button.setTitle("start video", for: UIControl.State.normal)
            button.backgroundColor = .gray
            button.addTarget(self, action: #selector(startVideo(btn:)), for: UIControl.Event.touchUpInside)
            renderView.addSubview(button)
            
            let playButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 70, y: UIScreen.main.bounds.height - 50, width: 50, height: 40))
            playButton.setTitle("play", for: UIControl.State.normal)
            playButton.backgroundColor = .gray
            playButton.addTarget(self, action: #selector(playMovie(btn:)), for: UIControl.Event.touchUpInside)
            renderView.addSubview(playButton)
        }else{
            let button = UIButton(frame: CGRect(x: 20, y: UIScreen.main.bounds.height - 50, width: 50, height: 40))
            button.setTitle("拍照", for: UIControl.State.normal)
            button.backgroundColor = .gray
            button.addTarget(self, action: #selector(takePhoto), for: UIControl.Event.touchUpInside)
            renderView.addSubview(button)
        }
        
        let filterButton = UIButton(frame: CGRect(x: 90, y: UIScreen.main.bounds.height - 50, width: 150, height: 40))
        filterButton.setTitle("选择滤镜", for: UIControl.State.normal)
        filterButton.backgroundColor = .gray
        filterButton.addTarget(self, action: #selector(ChoseFilter(btn:)), for: .touchUpInside)
        renderView.addSubview(filterButton)
        
        return renderView
    }
    @objc func takePhoto() {
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
        
        self.imageView.image = UIImage(contentsOfFile: filteredPath)
        
        self.renderView.removeFromSuperview()
        
//        // 如果需要处理回调，有下面两种写法
//        let dataOutput = PictureOutput()
//        dataOutput.encodedImageFormat = .png
//        dataOutput.encodedImageAvailableCallback = {imageData in
//            // 这里的imageData是截取到的数据，Data类型
//        }
//        self.camera --> dataOutput
//
        let imageOutput = PictureOutput()
        imageOutput.encodedImageFormat = .png
        imageOutput.imageAvailableCallback = {image in
            // 这里的image是截取到的数据，UIImage类型
            self.imageView.image = image
        }
        self.camera --> imageOutput
        
    }
    func addbutton() {
        let buttonX = UIButton(frame: CGRect.zero)
        buttonX.tag = 101
        buttonX.setTitle("拍视频", for: UIControl.State.normal)
        buttonX.addTarget(self, action: #selector(buttonClick(btn:)), for: UIControl.Event.touchUpInside)
        buttonX.backgroundColor = UIColor.gray
        let buttonY = UIButton(frame: CGRect.zero)
        
        buttonY.tag = 102
        buttonY.setTitle("拍照片", for: UIControl.State.normal)
        buttonY.addTarget(self, action: #selector(buttonClick(btn:)), for: UIControl.Event.touchUpInside)
        buttonY.backgroundColor = UIColor.gray
        
        let buttonZ = UIButton(frame: CGRect.zero)
        buttonZ.tag = 103
        buttonZ.setTitle("选图片", for: UIControl.State.normal)
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
        buttonX.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
        buttonX.heightAnchor.constraint(equalToConstant: 60).isActive = true

        buttonY.leftAnchor.constraint(equalTo: buttonX.rightAnchor,constant: 10).isActive = true
        buttonY.topAnchor.constraint(equalTo: buttonX.topAnchor).isActive = true
        buttonY.bottomAnchor.constraint(equalTo: buttonX.bottomAnchor).isActive = true

        buttonZ.leftAnchor.constraint(equalTo: buttonY.rightAnchor,constant: 10).isActive = true
        buttonZ.topAnchor.constraint(equalTo: buttonX.topAnchor).isActive = true
        buttonZ.bottomAnchor.constraint(equalTo: buttonX.bottomAnchor).isActive = true
        buttonZ.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -20).isActive = true
    }

}
extension ViewController {
    
    // MARK: - 实时视频滤镜，将相机捕获的图像经过处理显示在屏幕上
    func cameraFiltering() {
        
        // Camera的构造函数是可抛出错误的
        do {
            // 创建一个Camera的实例，Camera遵循ImageSource协议，用来从相机捕获数据
            /// Camera的指定构造器
            /// - Parameters:
            ///   - sessionPreset: 捕获视频的分辨率
            ///   - cameraDevice: 相机设备，默认为nil
            ///   - location: 前置相机还是后置相机，默认为.backFacing
            ///   - captureAsYUV: 是否采集为YUV颜色编码，默认为true
            /// - Throws: AVCaptureDeviceInput构造错误
            camera = try Camera(sessionPreset: AVCaptureSession.Preset.hd1280x720,
                                cameraDevice: nil,
                                location: .backFacing,
                                captureAsYUV: true)
            // Camera的指定构造器是有默认参数的，可以只传入sessionPreset参数
            // camera = try Camera(sessionPreset: AVCaptureSessionPreset1280x720)
            
        } catch {
            print(error)
            return
        }
        
        // 创建一个Luminance颜色处理滤镜
        filter = Pixellate()
        // 绑定处理链
        camera --> filter --> renderView
        
        // 开始捕捉数据
        self.camera.startCapture()
        // 结束捕捉数据
        // camera.stopCapture()
        
    }
    
    // MARK: - 从实时视频中截图图片
    func captureImageFromVideo() {
        
        // 启动实时视频滤镜
        self.cameraFiltering()
        
        // 设置保存路径
        guard let outputPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
        
        let originalPath = outputPath + "/originalImage.png"
        print("path: \(originalPath)")
        let originalURL = URL(fileURLWithPath: originalPath)
        
        let filteredPath = outputPath + "/filteredImage.png"
        print("path: \(filteredPath)")
        let filteredlURL = URL(fileURLWithPath: filteredPath)
        
        // 延迟1s执行，防止截到黑屏
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            
            // 保存相机捕捉到的图片
            self.camera.saveNextFrameToURL(originalURL, format: .png)
            
            // 保存滤镜后的图片
            self.filter.saveNextFrameToURL(filteredlURL, format: .png)
            
            // 如果需要处理回调，有下面两种写法
            
            let dataOutput = PictureOutput()
            dataOutput.encodedImageFormat = .png
            dataOutput.encodedImageAvailableCallback = {imageData in
                // 这里的imageData是截取到的数据，Data类型
            }
            self.camera --> dataOutput
            
            let imageOutput = PictureOutput()
            imageOutput.encodedImageFormat = .png
            imageOutput.imageAvailableCallback = {image in
                // 这里的image是截取到的数据，UIImage类型
            }
            self.camera --> imageOutput
        }
    }
    //MARK:-处理已有的视频
    func FilteringMovie(){
        do {
            let bundleURL = Bundle.main.resourceURL!
            let movieURL = URL(string:"sample_iPod.m4v", relativeTo:bundleURL)!
            movie = try MovieInput(url:movieURL, playAtActualSpeed:true)
            filter = SaturationAdjustment()
            movie --> filter --> renderView
            movie.start()
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }
    
    // MARK: - 处理静态图片
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
    
    // MARK: - 编写自定义的图像处理操作
    func customFilter() {
        
        // 获取文件路径
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "Custom", ofType: "fsh")!)
        
        var customFilter: BasicOperation
        
        do {
            // 从文件中创建自定义滤镜
            customFilter = try BasicOperation(fragmentShaderFile: url)
        } catch {
            
            print(error)
            return
        }
        
        // 进行滤镜处理
        imageView.image = imageView.image!.filterWithOperation(customFilter)
    }
    
    // MARK: - 操作组
    func operationGroup() {
        
        // 创建一个BrightnessAdjustment颜色处理滤镜
        let brightnessAdjustment = BrightnessAdjustment()
        brightnessAdjustment.brightness = 0.2
        
        // 创建一个ExposureAdjustment颜色处理滤镜
        let exposureAdjustment = ExposureAdjustment()
        exposureAdjustment.exposure = 0.5
        
        // 创建一个操作组
        let operationGroup = OperationGroup()
        
        // 给闭包赋值，绑定处理链
        operationGroup.configureGroup{input, output in
            input --> brightnessAdjustment --> exposureAdjustment --> output
        }
        
        // 进行滤镜处理
        imageView.image = imageView.image!.filterWithOperation(operationGroup)
    }
}

