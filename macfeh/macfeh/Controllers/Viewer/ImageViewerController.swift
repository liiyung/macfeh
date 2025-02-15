//
//  ImageViewerController.swift
//  macfeh
//
//  Created by Ushio on 12/12/16.
//

import Cocoa
import Quartz

class ImageViewerController: NSViewController, NSWindowDelegate {

    private var window: NSWindow?

    @IBOutlet private weak var imageViewScrollView: ImageViewerScrollView!
    @IBOutlet private weak var imageView: IKImageView!
    @IBOutlet private weak var loadingSpinner: NSProgressIndicator!

    var backgroundVisible: Bool = true;
    var shadowVisible: Bool = true;
    var representedImage: NSImage?
    var representedImageSize: NSSize?

    @IBAction func toggleBackground(_ sender: NSMenuItem?) { toggleBackground(); }
    @IBAction func toggleShadow(_ sender: NSMenuItem?) { toggleShadow(); }
    @IBAction func zoomToActualSize(_ sender: NSMenuItem?) { zoomToActualSize(); }
    @IBAction func zoomToFit(_ sender: NSMenuItem?) { zoomToFit(); }
    @IBAction func zoomImageIn(_ sender: NSMenuItem?) { zoomIn(); }
    @IBAction func zoomImageOut(_ sender: NSMenuItem?) { zoomOut(); }
    @IBAction func scaleWindowToImage(_ sender: NSMenuItem?) { scaleWindowToImage(); }

    override func viewDidLoad() {
        super.viewDidLoad();

        window = NSApp.windows.last!;
        window!.delegate = self;

        window!.styleMask.insert(.fullSizeContentView);
        window!.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = true;
        window!.isMovableByWindowBackground = true;

        imageViewScrollView.onZoom = { event in
            if event.deltaY < 0 {
                self.zoomOut();
            }
            else {
                self.zoomIn();
            }
        };

        loadingSpinner.startAnimation(self);
        loadingSpinner.isHidden = false;
    }

    func display(image atPath: String) {
        NSDocumentController.shared.noteNewRecentDocumentURL(URL(fileURLWithPath: atPath));

        DispatchQueue.global(qos: .background).async {
            if let image = NSImage(contentsOfFile: atPath) {
                let imagePixelSize = image.pixelSize;

                DispatchQueue.main.async {
                    self.imageView.setImageWith(URL(fileURLWithPath: atPath));

                    self.loadingSpinner.stopAnimation(self);
                    self.loadingSpinner.isHidden = true;

                    self.window!.maxSize = imagePixelSize;
                    self.window!.contentAspectRatio = imagePixelSize;

                    let mainScreenSize: NSSize = NSScreen.main!.frame.size;

                    // if image is smaller than screen ; if image width < screen width AND image height < screen height;
                    if imagePixelSize.width < mainScreenSize.width && imagePixelSize.height < mainScreenSize.height {
                        self.window!.setFrame(NSRect(x: self.window!.frame.origin.x,
                                                     y: self.window!.frame.origin.y,
                                                     width: imagePixelSize.width,
                                                     height: imagePixelSize.height),
                                                     display: false);
                        // for some reason, small images get zoomed out. this readjusts the already small image back to its original size
                        self.zoomToActualSize();

                    }
                    // if image isn't smaller than screen, it is larger. fix height at 600px, let width adapt
                    else {
                        // aspect ratio (image width) : (image height)
                        let aspectRatio = imagePixelSize.width / imagePixelSize.height;
                        // fix the new macfeh window height must maintain ratio and a certain size
                        let newWindowHeight: CGFloat = 250;
                        let newWindowWidth = aspectRatio * newWindowHeight;

                        self.window!.setFrame(NSRect(x: self.window!.frame.origin.x,
                                                     y: self.window!.frame.origin.y,
                                                     width: newWindowWidth,
                                                     height: newWindowHeight),
                                                     display: false);
                        
                    }
                    self.window!.title = NSString(string: atPath).lastPathComponent;

                    self.showBackground((NSApp.delegate as! AppDelegate).preferences.viewerDefaultsShowBackground);
                    self.showShadow((NSApp.delegate as! AppDelegate).preferences.viewerDefaultsEnableShadow);

                    self.representedImage = image;
                    
                }
            }
            else {
                print("ImageViewerController: No image at \"\(atPath)\"");
                
                DispatchQueue.main.async {
                    self.window?.close();
                }
            }
        }
    }

    @objc func zoomIn() {
        imageView.zoomIn(self);
    }

    @objc func zoomOut() {
        imageView.zoomOut(self);
        
        // dont allow the image to be zoomed out beyond the window frame
        if imageView.frame.width < window!.frame.width || imageView.frame.height < window!.frame.height {
            zoomToFit();
        }
    }

    @objc func zoomToFit() {
        imageView.zoomImageToFit(self);
        imageView.autoresizes = true;
    }

    @objc func zoomToActualSize() {
        imageView.zoomImageToActualSize(self);
    }

    @objc func toggleBackground() {
        showBackground(!backgroundVisible);
    }

    func showBackground(_ state: Bool) {
        if state {
            window!.isOpaque = true;
            window!.backgroundColor = NSColor(catalogName: NSColorList.Name(rawValue: "System"), colorName: NSColor.Name(rawValue: "windowBackgroundColor"));
        }
        else {
            window!.isOpaque = false;
            window!.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0);
        }
        
        backgroundVisible = state;
    }

    @objc func toggleShadow() {
        showShadow(!shadowVisible);
    }

    func showShadow(_ state: Bool) {
        window!.hasShadow = state;
        shadowVisible = state;
    }

    @objc func scaleWindowToImage() {
        window!.setContentSize(self.representedImage?.pixelSize ?? self.window!.frame.size);
        zoomToActualSize();
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        //todo: does this actually do anything?
        representedImage = nil;
        representedImageSize = nil;
        imageView = nil;
        window = nil;
        
        return true;
    }
}

