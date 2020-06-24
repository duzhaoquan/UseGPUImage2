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
    var movie: MovieInput!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "播放视频添加滤镜"
        view.backgroundColor = .white
        addbutton()
        
    }
    @objc func buttonClick(btn:UIButton){
        if btn.tag == 101 {
            
            
        }else if btn.tag == 102{
            playMovie(btn: btn)
        }else if btn.tag == 103{
            
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
        buttonX.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 5).isActive = true
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
            
            let documentsDir = try! FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            let fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
            movie = try? MovieInput(url:fileURL, playAtActualSpeed:true)

            let renderView1 = RenderView(frame:CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 60))
            view.addSubview(renderView1)
            filter = SaturationAdjustment()
            movie --> filter --> renderView1
//            movie.runBenchmark = true
            movie.start()
            
        }else{
            btn.setTitle("play", for: UIControl.State.normal)
            movie.cancel()
            
        }
    }
    

}
