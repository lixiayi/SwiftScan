//
//  ViewController.swift
//  SwiftScan
//
//  Created by xiaoyi li on 16/12/30.
//  Copyright © 2016年 xiaoyi li. All rights reserved.
//

import UIKit
import AVFoundation

let kMargin: CGFloat = 60.0
let kBorderW:CGFloat = 200
let kWidth = UIScreen.main.bounds.size.width
let kHeight = UIScreen.main.bounds.size.height

class ViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet var resultLabel: UILabel!

    var scanBackBtn : UIButton?
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    var _maskWithHole:CAShapeLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 中间视频采集框
        self.createView()
        
        // 初始化相机
        self.initialize()
        
        // 重绘覆盖层
        self.drawShapeLayer();
    }
    
    func createView() {
        let scanWindowH:CGFloat = (self.view.bounds.size.width) - kMargin * 2
        let scanWindowW:CGFloat = (self.view.bounds.size.width) - kMargin * 2
        
        let viewCenter: CGPoint = self.view.center;
        scanBackBtn = UIButton(frame: CGRect.init(x: kMargin, y: kBorderW, width: scanWindowW, height: scanWindowH))
        scanBackBtn?.setBackgroundImage(UIImage.init(named: "saomiaokuang"), for: .normal)
        scanBackBtn?.center = viewCenter
        self.view.addSubview(scanBackBtn!)

    }
    
    func drawShapeLayer() {
        //设置覆盖层
        _maskWithHole = CAShapeLayer()
        
        // 设置外围绘制区域
        let biggerRect:CGRect = CGRect(x: 0, y: 64, width: kWidth, height: kHeight - 64)
        
        //设置检边视图层
        let smallFrame: CGRect = (self.scanBackBtn?.frame)!
        let smallerRect = smallFrame
        
        // 绘制覆盖层
        let maskPath = UIBezierPath()
        maskPath.move(to: CGPoint(x: biggerRect.minX, y: biggerRect.minY))
        maskPath.addLine(to: CGPoint(x: biggerRect.minX, y: biggerRect.maxY))
        maskPath.addLine(to: CGPoint(x: biggerRect.maxX, y: biggerRect.maxY))
        maskPath.addLine(to: CGPoint(x: biggerRect.maxX, y: biggerRect.minY))
        maskPath.addLine(to: CGPoint(x: biggerRect.minX, y: biggerRect.minY))
        
        maskPath.addLine(to: CGPoint(x: smallerRect.minX, y: smallerRect.minY))
        maskPath.addLine(to: CGPoint(x: smallerRect.minX, y: smallerRect.maxY))
        maskPath.addLine(to: CGPoint(x: smallerRect.maxX, y: smallerRect.maxY))
        maskPath.addLine(to: CGPoint(x: smallerRect.maxX, y: smallerRect.minY))
        maskPath.addLine(to: CGPoint(x: smallerRect.minX, y: smallerRect.minY))
        
        // 设置覆盖层参数
        _maskWithHole?.path = maskPath.cgPath
        _maskWithHole?.fillRule = kCAFillRuleEvenOdd
        let rgbColor = UIColor(red: 0.2, green: 0.6, blue: 0.4, alpha: 1.0)
        _maskWithHole?.fillColor = rgbColor.cgColor
        self.view.layer.addSublayer(_maskWithHole!)
        self.view.layer.masksToBounds = true
        self.view.bringSubview(toFront: self.scanBackBtn!)

    }
    
    func initialize() {
        // 获取 AVCaptureDevice实例
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            // 获取 AVCaptureDeviceInput实例
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // 初始化 caputuresession
            captureSession = AVCaptureSession()
            
            // 把输入设备添加到session
            captureSession?.addInput(input)
            
            // 输出设备
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue:DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes  = [AVMetadataObjectTypeQRCode]
            
            // 预览层
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            self.view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
        } catch  {
            // 捕获错误
            print(error)
            return
        }

    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        guard metadataObjects.count > 0 else {
            print("没有任何扫描结果.")
            self.resultLabel.isHidden = true
            return
        }
        // 获取 metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // 获取扫描结果
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            if metadataObj.stringValue != nil {
                print("扫描结果：\(metadataObj.stringValue)")
                self.resultLabel.text = metadataObj.stringValue
                self.view.bringSubview(toFront: self.resultLabel)
                self.captureSession?.stopRunning()
            }
        }
    }
}

