//
//  NewCardViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-07.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class NewCardViewController: ModalCardViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    var toolsViewController: ToolsViewController!

    var addTextTapGesture: UITapGestureRecognizer!
    
    var hasEditedFront: Bool {
        get {
            let hasDrawn = frontDrawingView.canUndo
            let hasAddedTextOrImage = cardView.frontViewContentView.subviews.count > 1
            return hasDrawn || hasAddedTextOrImage
        }
    }
    var hasEditedBack: Bool {
        get {
            let hasDrawn = backDrawingView.canUndo
            let hasAddedTextOrImage = cardView.backViewContentView.subviews.count > 1
            return hasDrawn || hasAddedTextOrImage
        }
    }
    var canSaveCard: Bool {
        get {
            return (hasEditedFront && hasEditedBack) || isEditingExistingCard
        }
    }
    
    var frontDrawingView: SwiftyDrawView!
    var backDrawingView: SwiftyDrawView!
    
    var existingFrontView: UIImageView?
    var existingBackView: UIImageView?
    
    var dragableViews: [UIView] = []
    
    var preferredLeftButtonTitle = "Cancel"
    @IBOutlet weak var topLeftButton: UIButton!
    @IBOutlet weak var topRightButton: UIButton!
    @IBOutlet weak var textColorSlider: ColorSlider!
    @IBOutlet weak var titleLabel: UILabel!
    
    var isDrawing: Bool = false
    var isWriting: Bool = false
    
    var existingCard: CardSides?
    var isEditingExistingCard: Bool {
        get {
            return existingCard != nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCardView()
        topRightButton.isEnabled = canSaveCard
    }
    
    func setupCardView() {
        cardView = CardView(frame: cardViewPlaceholder.frame)
        view.addSubview(cardView)
        
        if let existingCard = existingCard, let frontImage = existingCard.frontImage, let backImage = existingCard.backImage {
            existingFrontView = UIImageView(image: frontImage)
            existingFrontView!.frame = cardView.frontViewContentView.bounds
            cardView.frontViewContentView.addSubview(existingFrontView!)
            
            existingBackView = UIImageView(image: backImage)
            existingBackView!.frame = cardView.backViewContentView.bounds
            cardView.backViewContentView.addSubview(existingBackView!)
        }
        
        frontDrawingView = SwiftyDrawView(frame: cardView.frontViewContentView.bounds)
        frontDrawingView.isEnabled = false
        cardView.frontViewContentView.addSubview(frontDrawingView)
        backDrawingView = SwiftyDrawView(frame: cardView.backViewContentView.bounds)
        backDrawingView.isEnabled = false
        cardView.backViewContentView.addSubview(backDrawingView)
        
        addTextTapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedCard))
        cardView.addGestureRecognizer(addTextTapGesture)
        
        titleLabel.text = "Front"
    }

    override func viewDidLayoutSubviews() {
        cardView.frame = cardViewPlaceholder.frame
        frontDrawingView.frame = frontDrawingView.superview!.bounds
        backDrawingView.frame = backDrawingView.superview!.bounds
        
        existingFrontView?.frame = cardView.frontViewContentView.bounds
        existingBackView?.frame = cardView.backViewContentView.bounds
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return [.portrait, .portraitUpsideDown]
        }
    }
    
    @objc func flipCard() {
        cardView.flip(animated: true) { (finished) in
            // flip animation finished
        }
        
        titleLabel.text = cardView.isShowingFront ? "Front" : "Back"
    }
    
    @IBAction func topLeftAction(_ sender: Any) {
        if isDrawing {
            undoDrawing()
        } else if isWriting {
            
        } else {
            close(sender)
        }
    }
    
    @IBAction func topRightAction(_ sender: Any) {
        if isDrawing {
            stopDrawing()
        } else if isWriting {
            stopWriting()
        } else {
            if canSaveCard {
                saveCard(cardView)
                if isEditingExistingCard {
                    dismiss(animated: true, completion: nil)
                } else {
                    UIView.setAnimationsEnabled(false)
                    preferredLeftButtonTitle = "Done"
                    topLeftButton.setTitle(preferredLeftButtonTitle, for: .normal)
                    topLeftButton.layoutIfNeeded()
                    UIView.setAnimationsEnabled(true)

                    animateOutCard(cardView, direction: 1)
                    setupCardView()
                    animateInNewCard(cardView)
                }
            }
        }
    }
    
    @objc func tappedCard() {
        if isDrawing {
            
        } else if isWriting {
            stopWriting()
        } else {
            addText()
        }
    }
    
    var draggedViewOriginalCenter: CGPoint?
    @objc func dragView(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let draggedView = gestureRecognizer.view else { return }
        
        if gestureRecognizer.state == .began {
            draggedViewOriginalCenter = draggedView.center
        } else if gestureRecognizer.state == .changed || gestureRecognizer.state == .ended {
            let translation = gestureRecognizer.translation(in: draggedView.superview)
            let draggedViewOriginalCenter = self.draggedViewOriginalCenter!
            
            draggedView.center.x = draggedViewOriginalCenter.x + translation.x
            draggedView.center.y = draggedViewOriginalCenter.y + translation.y
            
            if (abs(draggedView.center.x - draggedView.superview!.bounds.size.width / 2) < 5) {
                draggedView.center.x = draggedView.superview!.bounds.size.width / 2
            }
        }
    }
    
    var viewOriginalTransform: CGAffineTransform?
    @objc func resizeView(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let view = gestureRecognizer.view else { return }
        
        if gestureRecognizer.state == .began {
            viewOriginalTransform = view.transform
        } else if gestureRecognizer.state == .changed || gestureRecognizer.state == .ended {
            let scale = gestureRecognizer.scale
            view.transform = viewOriginalTransform!.scaledBy(x: scale, y: scale)
            
            let finalScale = sqrt(pow(view.transform.a, 2) + pow(view.transform.c, 2))
            if finalScale < 1.05 && finalScale > 0.95 {
                let angle = atan2f(Float(view.transform.b), Float(view.transform.a));
                view.transform = CGAffineTransform.init(rotationAngle: CGFloat(angle))
            }
        }
    }
    
    @objc func rotateView(_ gestureRecognizer: UIRotationGestureRecognizer) {
        guard let view = gestureRecognizer.view else { return }
        
        if gestureRecognizer.state == .began {
            viewOriginalTransform = view.transform
        } else if gestureRecognizer.state == .changed || gestureRecognizer.state == .ended {
            let rotation = gestureRecognizer.rotation
            view.transform = viewOriginalTransform!.rotated(by: rotation)
            
            let angle = atan2f(Float(view.transform.b), Float(view.transform.a));
            if angle < 0.05 && angle > -0.05 {
                let scale = sqrt(pow(view.transform.a, 2) + pow(view.transform.c, 2))
                view.transform = CGAffineTransform.init(scaleX: scale, y: scale)
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == otherGestureRecognizer.view {
            if (gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) || gestureRecognizer.isKind(of: UIRotationGestureRecognizer.self)) &&
                (otherGestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) || otherGestureRecognizer.isKind(of: UIRotationGestureRecognizer.self)) {
                return true
            }
        }
        return false
    }
    
    func saveCard(_ cardView: CardView) {
        var size = cardView.frontViewContentView.bounds.size
        size.width *= UIScreen.main.scale
        size.height *= UIScreen.main.scale
        
        UIGraphicsBeginImageContext(size)
        cardView.frontViewContentView.drawHierarchy(in: CGRect(origin: CGPoint.zero, size: size), afterScreenUpdates: false)
        let frontImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        UIGraphicsBeginImageContext(size)
        cardView.backViewContentView.drawHierarchy(in: CGRect(origin: CGPoint.zero, size: size), afterScreenUpdates: false)
        let backImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        do {
            let imageURLs = existingCard ?? ImageManager.imagesURLsForNewCard()
            if let frontImageURL = imageURLs.frontImageURL, let backImageURL = imageURLs.backImageURL {
                try frontImage?.pngData()?.write(to: frontImageURL)
                try backImage?.pngData()?.write(to: backImageURL)
            }
        }
        catch {
            print("failed to write image :(")
        }
    }
    
    // MARK: - Text
    
    @objc func addText() {
        guard let currentView = cardView.isShowingFront ? cardView.frontViewContentView : cardView.backViewContentView else {
            return
        }
        
        var center = CGPoint(x: currentView.bounds.size.width * 0.5, y: currentView.bounds.size.height * 0.35)
        var didHit = false
        while currentView.hitTest(center, with: nil)?.isKind(of: UITextView.self) ?? false {
            center.y += 10
            didHit = true
        }
        if didHit {
            center.y += 16
        }
        
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textColor = .black
        textView.isScrollEnabled = false
        textView.font = UIFont(name: "SFCompactRounded-Bold", size: 28)
        textView.delegate = self
        textView.textAlignment = .center
        textView.sizeToFit()
        textView.center = center
        currentView.addSubview(textView)
        textView.becomeFirstResponder()
        
        cardView.layer.rasterizationScale = UIScreen.main.scale;
        currentView.layer.rasterizationScale = UIScreen.main.scale;
        textView.layer.rasterizationScale = UIScreen.main.scale;
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragView))
        panGesture.maximumNumberOfTouches = 1
        textView.addGestureRecognizer(panGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(resizeView))
        pinchGesture.delegate = self
        textView.addGestureRecognizer(pinchGesture)
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateView))
        rotateGesture.delegate = self
        textView.addGestureRecognizer(rotateGesture)
        dragableViews.append(textView)
    }
    
    var currentTextView: UITextView?
    func textViewDidBeginEditing(_ textView: UITextView) {
        isWriting = true
        currentTextView = textView
        
        textColorSlider.value = textColorSlider.value(forColorValue: textView.textColor!)
        textColorSlider.isHidden = false
        textColorSlider.updateColorIndicator()
        
        titleLabel.isHidden = true
        
        UIView.setAnimationsEnabled(false)
        topLeftButton.isHidden = true
        topRightButton.setTitle("Done", for: .normal)
        topRightButton.isEnabled = true
        topRightButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
        
        textView.spellCheckingType = .yes
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        isWriting = false
        currentTextView = nil
        
        textColorSlider.isHidden = true
        titleLabel.isHidden = false
        
        UIView.setAnimationsEnabled(false)
        topLeftButton.isHidden = false
        topRightButton.setTitle("Save Card", for: .normal)
        topRightButton.isEnabled = canSaveCard
        topRightButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
        
        textView.spellCheckingType = .no
        
        let text = textView.text
        textView.text = ""
        textView.text = text
        
        if textView.text == "" {
            textView.removeFromSuperview()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (range.location == 0 && range.length == 0 && text == "" && textView.text == "") {
            textView.removeFromSuperview()
            stopWriting()
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        var cardSizeMinusMargin = textView.superview?.bounds.size ?? CGSize.zero
        cardSizeMinusMargin.width -= 32
        cardSizeMinusMargin.height -= 32
        
        let oldCenter = textView.center
        textView.frame.size = textView.sizeThatFits(cardSizeMinusMargin)
        textView.center = oldCenter
    }
    
    func stopWriting() {
        view.endEditing(true)
    }
    
    @IBAction func changeTextColor(_ sender: ColorSlider) {
        currentTextView?.textColor = sender.colorValue
    }
    
    // MARK: - Image
    
    @objc func showImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let pasteAction: UIAlertAction?
        if let pasteBoardImage = UIPasteboard.general.image {
            pasteAction = UIAlertAction(title: "Paste", style: .default) { (_) in
                self.addImage(pasteBoardImage)
            }
        } else {
            pasteAction = nil
        }
        
        let cameraAction: UIAlertAction?
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { (_) in
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            })
        } else {
            cameraAction = nil
        }
        
        if pasteAction != nil || cameraAction != nil {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.popoverPresentationController?.sourceView = toolsViewController.imageButton
            alertController.popoverPresentationController?.sourceRect = toolsViewController.imageButton.bounds
            if let pasteAction = pasteAction { alertController.addAction(pasteAction) }
            if let cameraAction = cameraAction { alertController.addAction(cameraAction) }
            alertController.addAction(UIAlertAction(title: "Library", style: .default, handler: { (_) in
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            addImage(image)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }

    
    @objc func addImage(_ image: UIImage, toView view: UIView? = nil) {
        let currentView: UIView = view ?? (cardView.isShowingFront ? cardView.frontViewContentView : cardView.backViewContentView)
        
        let center = CGPoint(x: currentView.bounds.size.width * 0.5, y: currentView.bounds.size.height * 0.5)
        
        let firstTextView = currentView.subviews.first { (subview) -> Bool in
            subview.isKind(of: UITextView.self)
        }
        
        let imageView = UIImageView()
        imageView.image = image
        imageView.backgroundColor = .clear
        
        imageView.bounds.size = image.size
        let xScale = (currentView.bounds.size.width * 0.8) / imageView.bounds.size.width
        let yScale = (currentView.bounds.size.height * 0.8) / imageView.bounds.size.height
        let minScale = min(xScale, yScale)
        if minScale < 1.0 {
            imageView.bounds.size.width *= minScale
            imageView.bounds.size.height *= minScale
        }
        
        imageView.center = center
        imageView.frame = CGRect(
            x: round(imageView.frame.origin.x),
            y: round(imageView.frame.origin.y),
            width: round(imageView.frame.size.width),
            height: round(imageView.frame.size.height)
        )
        if let firstTextView = firstTextView {
            currentView.insertSubview(imageView, belowSubview: firstTextView)
        } else {
            currentView.addSubview(imageView)
        }
        
        imageView.isUserInteractionEnabled = true
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragView))
        imageView.addGestureRecognizer(panGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(resizeView))
        pinchGesture.delegate = self
        imageView.addGestureRecognizer(pinchGesture)
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateView))
        rotateGesture.delegate = self
        imageView.addGestureRecognizer(rotateGesture)
        dragableViews.append(imageView)
    }
    
    // MARK: - Drawing
    
    @objc func startDrawing() {
        guard let currentDrawingView = cardView.isShowingFront ? frontDrawingView : backDrawingView else {
            return
        }
        
        isDrawing = true
        
        let slidersViewController = infoNavigationController.viewControllers.last as! SlidersViewController
        slidersViewController.loadViewIfNeeded()
        slidersViewController.colorSlider.addTarget(self, action: #selector(changeLineColor(_:)), for: .valueChanged)
        slidersViewController.widthSlider.addTarget(self, action: #selector(changeLineWidth(_:)), for: .valueChanged)
        
        if let colorSliderValue = UserDefaults.standard.object(forKey: "colorSliderValue") as? Float {
            slidersViewController.colorSlider.value = colorSliderValue
        }
        if let widthSliderValue = UserDefaults.standard.object(forKey: "widthSliderValue") as? Float {
            slidersViewController.widthSlider.value = widthSliderValue
        }
        currentDrawingView.brush.color = slidersViewController.colorSlider.colorValue
        currentDrawingView.brush.width = slidersViewController.widthSlider.widthValue
        
        currentDrawingView.isEnabled = true
        addTextTapGesture.isEnabled = false
        for view in dragableViews {
            view.isUserInteractionEnabled = false
        }
        
        titleLabel.isHidden = false
        
        UIView.setAnimationsEnabled(false)
        topLeftButton.setTitle("Undo", for: .normal)
        topLeftButton.setImage(nil, for: .normal)
        topLeftButton.layoutIfNeeded()
        
        topRightButton.setTitle("Done", for: .normal)
        topRightButton.isEnabled = true
        topRightButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)

        view.endEditing(true)
    }
    
    func stopDrawing() {
        guard let currentDrawingView = cardView.isShowingFront ? frontDrawingView : backDrawingView else {
            return
        }
        
        isDrawing = false
        
        currentDrawingView.isEnabled = false
        addTextTapGesture.isEnabled = true
        for view in dragableViews {
            view.isUserInteractionEnabled = true
        }
        
        titleLabel.isHidden = false
        
        UIView.setAnimationsEnabled(false)
        topLeftButton.setTitle(preferredLeftButtonTitle, for: .normal)
//        topLeftButton.setImage(UIImage(named: "close button"), for: .normal)
        topLeftButton.layoutIfNeeded()
        
        topRightButton.setTitle("Save Card", for: .normal)
        topRightButton.isEnabled = canSaveCard
        topRightButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
        
        infoNavigationController?.popToRootViewController(animated: false)
    }
    
    func undoDrawing() {
        guard let currentDrawingView = cardView.isShowingFront ? frontDrawingView : backDrawingView else {
            return
        }
        
        currentDrawingView.undo()
    }
    
    @objc func changeLineColor(_ sender: ColorSlider) {
        guard let currentDrawingView = cardView.isShowingFront ? frontDrawingView : backDrawingView else {
            return
        }
        
        UserDefaults.standard.set(sender.value, forKey: "colorSliderValue")
        currentDrawingView.brush.color = sender.colorValue
    }
    
    @objc func changeLineWidth(_ sender: WidthSlider) {
        guard let currentDrawingView = cardView.isShowingFront ? frontDrawingView : backDrawingView else {
            return
        }
        
        UserDefaults.standard.set(sender.value, forKey: "widthSliderValue")
        currentDrawingView.brush.width = sender.widthValue
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedInfoNavigation" {
            infoNavigationController = segue.destination as? UINavigationController
            
            let toolsViewController = self.infoNavigationController.viewControllers.last as! ToolsViewController
            toolsViewController.loadViewIfNeeded()
            toolsViewController.drawButton.addTarget(self, action: #selector(startDrawing), for: .touchUpInside)
            toolsViewController.textButton.addTarget(self, action: #selector(addText), for: .touchUpInside)
            toolsViewController.imageButton.addTarget(self, action: #selector(showImagePicker), for: .touchUpInside)
            toolsViewController.flipButton.addTarget(self, action: #selector(flipCard), for: .touchUpInside)
            self.toolsViewController = toolsViewController
        }
    }

}
