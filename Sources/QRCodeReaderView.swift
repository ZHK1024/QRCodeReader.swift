/*
 * QRCodeReader.swift
 *
 * Copyright 2014-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

open class QRCodeReaderView: UIView, QRCodeReaderDisplayable {
    public lazy var overlayView: QRCodeReaderViewOverlay? = {
        let ov = ReaderOverlayView()
        
        ov.backgroundColor                           = .clear
        ov.clipsToBounds                             = true
        ov.translatesAutoresizingMaskIntoConstraints = false
        
        return ov
    }()
    
    public let cameraView: UIView = {
        let cv = UIView()
        
        cv.clipsToBounds                             = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        
        return cv
    }()
    
    public lazy var titleLabel: UILabel? = {
        let tl = UILabel()
        
        tl.translatesAutoresizingMaskIntoConstraints = false
        tl.textAlignment                              = .center
        tl.textColor                                  = .white
        tl.font                                       = UIFont.boldSystemFont(ofSize: 17)
        
        return tl
    }()
    
    public lazy var backButton: UIButton? = {
        let bb = UIButton()
        
        bb.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
            let image = UIImage(systemName: "chevron.left.circle.fill", withConfiguration: config)
            bb.setImage(image, for: .normal)
            bb.tintColor = .white
        }
        
        return bb
    }()
    
    public lazy var switchCameraButton: UIButton? = {
        let scb = SwitchCameraButton()
        
        scb.translatesAutoresizingMaskIntoConstraints = false
        
        return scb
    }()
    
    public lazy var toggleTorchButton: UIButton? = {
        let ttb = ToggleTorchButton()
        
        ttb.translatesAutoresizingMaskIntoConstraints = false
        
        return ttb
    }()
    
    private weak var reader: QRCodeReader?
    
    public func setupComponents(with builder: QRCodeReaderViewControllerBuilder) {
        self.reader               = builder.reader
        reader?.lifeCycleDelegate = self
        
        addComponents()
        
        titleLabel?.isHidden         = !builder.showTitle
        backButton?.isHidden         = !builder.showBackButton
        switchCameraButton?.isHidden = !builder.showSwitchCameraButton
        toggleTorchButton?.isHidden  = !builder.showTorchButton
        overlayView?.isHidden        = !builder.showOverlayView
        
        if builder.showTitle {
            titleLabel?.text = builder.titleText
        }
        
        guard let scb = switchCameraButton, let ttb = toggleTorchButton, let ov = overlayView else { return }
        
        let views: [String: Any] = ["cv": cameraView, "ov": ov, "scb": scb, "ttb": ttb]
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[cv]|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[cv]|", options: [], metrics: nil, views: views))
        
        // Setup title label with safe area
        if builder.showTitle, let tl = titleLabel {
            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    tl.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
                    tl.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                    tl.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                    tl.heightAnchor.constraint(equalToConstant: 44)
                ])
            } else {
                NSLayoutConstraint.activate([
                    tl.topAnchor.constraint(equalTo: topAnchor, constant: 20),
                    tl.leadingAnchor.constraint(equalTo: leadingAnchor),
                    tl.trailingAnchor.constraint(equalTo: trailingAnchor),
                    tl.heightAnchor.constraint(equalToConstant: 44)
                ])
            }
        }
        
        // Setup back button with safe area
        if builder.showBackButton, let bb = backButton {
            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    bb.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
                    bb.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
                    bb.widthAnchor.constraint(equalToConstant: 44),
                    bb.heightAnchor.constraint(equalToConstant: 44)
                ])
            } else {
                NSLayoutConstraint.activate([
                    bb.topAnchor.constraint(equalTo: topAnchor, constant: 20),
                    bb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                    bb.widthAnchor.constraint(equalToConstant: 44),
                    bb.heightAnchor.constraint(equalToConstant: 44)
                ])
            }
        }
        
        // Setup switch camera button with safe area
        if builder.showSwitchCameraButton {
            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    scb.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
                    scb.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                    scb.widthAnchor.constraint(equalToConstant: 70),
                    scb.heightAnchor.constraint(equalToConstant: 50)
                ])
            } else {
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[scb(50)]", options: [], metrics: nil, views: views))
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[scb(70)]|", options: [], metrics: nil, views: views))
            }
        }
        
        // Setup toggle torch button with safe area
        if builder.showTorchButton {
            if #available(iOS 11.0, *) {
                NSLayoutConstraint.activate([
                    ttb.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
                    ttb.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                    ttb.widthAnchor.constraint(equalToConstant: 70),
                    ttb.heightAnchor.constraint(equalToConstant: 50)
                ])
            } else {
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[ttb(50)]", options: [], metrics: nil, views: views))
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[ttb(70)]", options: [], metrics: nil, views: views))
            }
        }
        
        for attribute in Array<NSLayoutConstraint.Attribute>([.left, .top, .right, .bottom]) {
            addConstraint(NSLayoutConstraint(item: ov, attribute: attribute, relatedBy: .equal, toItem: cameraView, attribute: attribute, multiplier: 1, constant: 0))
        }
        
        if let readerOverlayView = overlayView as? ReaderOverlayView {
            readerOverlayView.rectOfInterest = builder.rectOfInterest
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        reader?.previewLayer.frame = bounds
    }
    
    // MARK: - Scan Result Indication
    
    func startTimerForBorderReset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.overlayView?.setState(.normal)
        }
    }
    
    func addRedBorder() {
        self.startTimerForBorderReset()
        
        self.overlayView?.setState(.wrong)
    }
    
    func addGreenBorder() {
        self.startTimerForBorderReset()
        
        self.overlayView?.setState(.valid)
    }
    
    @objc public func setNeedsUpdateOrientation() {
        setNeedsDisplay()
        
        overlayView?.setNeedsDisplay()
        
        if let connection = reader?.previewLayer.connection, connection.isVideoOrientationSupported {
            let application                    = UIApplication.shared
            let orientation                    = UIDevice.current.orientation
            let supportedInterfaceOrientations = application.supportedInterfaceOrientations(for: application.keyWindow)
            
            connection.videoOrientation = QRCodeReader.videoOrientation(deviceOrientation: orientation, withSupportedOrientations: supportedInterfaceOrientations, fallbackOrientation: connection.videoOrientation)
        }
    }
    
    // MARK: - Convenience Methods
    
    private func addComponents() {
#if swift(>=4.2)
        let notificationName = UIDevice.orientationDidChangeNotification
#else
        let notificationName = NSNotification.Name.UIDeviceOrientationDidChange
#endif
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.setNeedsUpdateOrientation), name: notificationName, object: nil)
        
        addSubview(cameraView)
        
        if let ov = overlayView {
            addSubview(ov)
        }
        
        if let tl = titleLabel {
            addSubview(tl)
        }
        
        if let bb = backButton {
            addSubview(bb)
        }
        
        if let scb = switchCameraButton {
            addSubview(scb)
        }
        
        if let ttb = toggleTorchButton {
            addSubview(ttb)
        }
        
        if let reader = reader {
            cameraView.layer.insertSublayer(reader.previewLayer, at: 0)
            
            setNeedsUpdateOrientation()
        }
    }
}

extension QRCodeReaderView: QRCodeReaderLifeCycleDelegate {
    func readerDidStartScanning() {
        setNeedsUpdateOrientation()
    }
    
    func readerDidStopScanning() {}
}
