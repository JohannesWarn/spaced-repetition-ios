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
    var canSaveDraft: Bool {
        get {
            return (hasEditedFront || hasEditedBack)
        }
    }
    
    var frontDrawingView: SwiftyDrawView!
    var backDrawingView: SwiftyDrawView!
    
    var existingFrontView: UIImageView?
    var existingBackView: UIImageView?
    
    var dragableViews: [UIView] = []
    
    var hasSavedCard = false
    var preferredLeftButtonTitle: String {
        get {
            if isEditingExistingCard {
                return "Cancel"
            } else {
                if hasEditedFront || hasEditedBack {
                    return "Cancel"
                } else if hasSavedCard {
                    return "Done"
                } else {
                    return "Cancel"
                }
            }
        }
    }
    var preferredRightButtonTitle: String {
        get {
            if canSaveCard {
                return "Save Card"
            } else {
                return "Save Draft"
            }
        }
    }
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
    var isEditingDraft: Bool {
        get {
            if let level = existingCard?.level {
                return level == 0
            }
            return false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCardView()
        topRightButton.isEnabled = canSaveDraft || canSaveCard
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        var size = cardView.frontViewContentView.bounds.size
        size.width *= UIScreen.main.scale
        size.height *= UIScreen.main.scale
        
        if hasEditedFront {
            UIGraphicsBeginImageContext(size)
            cardView.frontViewContentView.drawHierarchy(in: CGRect(origin: CGPoint.zero, size: size), afterScreenUpdates: false)
            let frontImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let pngData = frontImage?.pngData() {
                coder.encode(pngData, forKey: "frontImage")
            }
        }
        
        if hasEditedBack {
            UIGraphicsBeginImageContext(size)
            cardView.backViewContentView.drawHierarchy(in: CGRect(origin: CGPoint.zero, size: size), afterScreenUpdates: false)
            let backImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let pngData = backImage?.pngData() {
                coder.encode(pngData, forKey: "backImage")
            }
        }
        
        if let existingCard = existingCard {
            coder.encode(existingCard.name, forKey: "existingCard.name")
            coder.encode(existingCard.level, forKey: "existingCard.level")
        }
        
        super.encodeRestorableState(with: coder)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let pngData = coder.decodeObject(forKey: "frontImage") as? Data {
            let frontImage = UIImage(data: pngData)
            existingFrontView?.removeFromSuperview()
            existingFrontView = UIImageView(image: frontImage)
            existingFrontView!.frame = cardView.frontViewContentView.bounds
            cardView.frontViewContentView.insertSubview(existingFrontView!, at: 0)
        }
        if let pngData = coder.decodeObject(forKey: "backImage") as? Data {
            let backImage = UIImage(data: pngData)
            existingBackView?.removeFromSuperview()
            existingBackView = UIImageView(image: backImage)
            existingBackView!.frame = cardView.backViewContentView.bounds
            cardView.backViewContentView.insertSubview(existingBackView!, at: 0)
        }
        if
            let name = coder.decodeObject(forKey: "existingCard.name") as? String
        {
            let level = coder.decodeInteger(forKey: "existingCard.level")
            let frontImageURL = ImageManager.imageURL(name: name, level: level, suffix: "front")
            let backImageURL = ImageManager.imageURL(name: name, level: level, suffix: "back")
            self.existingCard = CardSides(name: name, level: level, frontImage: nil, backImage: nil, frontImageURL: frontImageURL, backImageURL: backImageURL)
        }
        
        topRightButton.setTitle(preferredRightButtonTitle, for: .normal)
        topRightButton.isEnabled = canSaveDraft || canSaveCard
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
        frontDrawingView.isUserInteractionEnabled = false
        cardView.frontViewContentView.addSubview(frontDrawingView)
        backDrawingView = SwiftyDrawView(frame: cardView.backViewContentView.bounds)
        backDrawingView.isEnabled = false
        backDrawingView.isUserInteractionEnabled = false
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
            if hasEditedBack || hasEditedFront {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.popoverPresentationController?.sourceView = topLeftButton
                alertController.popoverPresentationController?.sourceRect = topLeftButton.bounds
                
                if !isEditingExistingCard {
                    alertController.addAction(UIAlertAction(title: "Save as Draft", style: .default, handler: { (_) in
                        let (success, error) = self.saveCard(self.cardView, toDrafts: true)
                        if success {
                            self.close(sender)
                        } else {
                            self.pressentError(error, title: "Error Saving Card")
                        }
                    }))
                    alertController.addAction(UIAlertAction(title: "Don’t Save", style: .destructive, handler: { (_) in
                        self.close(sender)
                    }))
                } else {
                    alertController.addAction(UIAlertAction(title: "Don’t Save Changes", style: .default, handler: { (_) in
                        self.close(sender)
                    }))
                }
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alertController, animated: true, completion: nil)
            } else {
                close(sender)
            }
        }
    }
    
    @IBAction func topRightAction(_ sender: Any) {
        if isDrawing {
            stopDrawing()
        } else if isWriting {
            stopWriting()
        } else {
            if canSaveDraft || canSaveCard {
                let savedCard: Bool
                let error: Error?
                if canSaveCard {
                    (savedCard, error) = self.saveCard(self.cardView, toDrafts: false)
                } else {
                    (savedCard, error) = self.saveCard(self.cardView, toDrafts: true)
                }
                
                if savedCard {
                    if isEditingExistingCard {
                        dismiss(animated: true, completion: nil)
                    } else {
                        animateOutCard(cardView, direction: 1)
                        setupCardView()
                        animateInNewCard(cardView)
                        
                        UIView.setAnimationsEnabled(false)
                        hasSavedCard = true
                        topLeftButton.setTitle(preferredLeftButtonTitle, for: .normal)
                        topLeftButton.layoutIfNeeded()
                        UIView.setAnimationsEnabled(true)
                    }
                } else {
                    self.pressentError(error, title: "Error Saving Card")
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
        guard !isWriting else { return }
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
        guard !isWriting else { return }
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
    
    func pressentError(_ error: Error?, title: String?) {
        let alert = UIAlertController(title: title, message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func imagesForCardView(_ cardView: CardView) -> (front: UIImage?, back: UIImage?) {
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
        
        return (frontImage, backImage)
    }
    
    func saveCard(_ cardView: CardView, toDrafts isDraft: Bool = false) -> (success: Bool, error: Error?) {
        let images = imagesForCardView(cardView)
        
        do {
            let imageURLs = existingCard ?? ImageManager.imagesURLsForNewCard(isDraft: isDraft)
            if let frontImageURL = imageURLs.frontImageURL, let backImageURL = imageURLs.backImageURL {
                try images.front?.pngData()?.write(to: frontImageURL)
                try images.back?.pngData()?.write(to: backImageURL)
                
                if let existingCard = existingCard, existingCard.level == 0 {
                    ImageManager.move(card: existingCard, toLevel: 1)
                }
            }
        }
        catch let error {
            return (false, error)
        }
        return (true, nil)
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
        
        let fontSize = ceil(cardView.frame.width / 10.0)
        
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textColor = .black
        textView.isScrollEnabled = false
        textView.font = UIFont(name: "SFCompactRounded-Bold", size: fontSize)
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
        
        for view in dragableViews {
            if view != textView {
                view.isUserInteractionEnabled = false
            }
        }
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.viewOriginalTransform = textView.transform
            textView.transform = .identity
        })
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        isWriting = false
        currentTextView = nil
        
        textColorSlider.isHidden = true
        titleLabel.isHidden = false
        
        UIView.setAnimationsEnabled(false)
        topLeftButton.setTitle(preferredLeftButtonTitle, for: .normal)
        topLeftButton.layoutIfNeeded()
        topLeftButton.isHidden = false
        topRightButton.setTitle(preferredRightButtonTitle, for: .normal)
        topRightButton.isEnabled = canSaveDraft || canSaveCard
        topRightButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
        
        textView.spellCheckingType = .no
        
        let text = textView.text
        textView.text = ""
        textView.text = text
        
        if textView.text == "" {
            textView.removeFromSuperview()
        }
        
        for view in dragableViews {
            view.isUserInteractionEnabled = true
        }
        if let viewOriginalTransform = self.viewOriginalTransform {
            UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
                textView.transform = viewOriginalTransform
                self.viewOriginalTransform = nil
            })
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (range.location == 0 && range.length == 0 && text == "" && textView.text == "") {
            textView.removeFromSuperview()
            stopWriting()
            // manually cann didEndEditing since it isn't triggered when the textview has been removed, but we want to trigger a UI update
            textViewDidEndEditing(textView)
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let margin = ceil(cardView.frame.width / 8.5)
        var cardSizeMinusMargin = textView.superview?.bounds.size ?? CGSize.zero
        cardSizeMinusMargin.width -= margin
        cardSizeMinusMargin.height -= margin
        
        let oldCenter = textView.center
        textView.frame.size = textView.sizeThatFits(cardSizeMinusMargin)
        normaliseSize(forView: textView)
        textView.center = oldCenter
    }
    
    func normaliseSize(forView view: UIView) {
        view.frame.size.width = ceil(view.frame.size.width / 2.0) * 2.0
        view.frame.size.height = ceil(view.frame.size.height / 2.0) * 2.0
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
        
        let otherSideAction: UIAlertAction?
        if (cardView.isShowingFront && hasEditedBack) || (!cardView.isShowingFront && hasEditedFront) {
            let title = cardView.isShowingFront ? "Back Side" : "Front Side"
            otherSideAction = UIAlertAction(title: title, style: .default, handler: { (_) in
                let images = self.imagesForCardView(self.cardView)
                if let image = self.cardView.isShowingFront ? images.back : images.front {
                    self.addImage(image, scale: 1)
                }
            })
        } else {
            otherSideAction = nil
        }
        
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
        
        let libraryAction = UIAlertAction(title: "Library", style: .default, handler: { (_) in
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        })
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = toolsViewController.imageButton
        alertController.popoverPresentationController?.sourceRect = toolsViewController.imageButton.bounds
        if let pasteAction = pasteAction { alertController.addAction(pasteAction) }
        if let otherSideAction = otherSideAction { alertController.addAction(otherSideAction) }
        if let cameraAction = cameraAction { alertController.addAction(cameraAction) }
        alertController.addAction(libraryAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            addImage(image)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }

    
    @objc func addImage(_ image: UIImage, toView view: UIView? = nil, scale: CGFloat = 0.8) {
        let currentView: UIView = view ?? (cardView.isShowingFront ? cardView.frontViewContentView : cardView.backViewContentView)
        
        let center = CGPoint(x: currentView.bounds.size.width * 0.5, y: currentView.bounds.size.height * 0.5)
        
        let imageView = UIImageView()
        imageView.image = image
        imageView.backgroundColor = .clear
        
        imageView.bounds.size = image.size
        let xScale = (currentView.bounds.size.width * scale) / imageView.bounds.size.width
        let yScale = (currentView.bounds.size.height * scale) / imageView.bounds.size.height
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
        if let currentDrawingView = cardView.isShowingFront ? frontDrawingView : backDrawingView {
            currentView.insertSubview(imageView, belowSubview: currentDrawingView)
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
        
        UIView.setAnimationsEnabled(false)
        topLeftButton.setTitle(preferredLeftButtonTitle, for: .normal)
        topLeftButton.layoutIfNeeded()
        
        topRightButton.setTitle(preferredRightButtonTitle, for: .normal)
        topRightButton.isEnabled = canSaveDraft || canSaveCard
        topRightButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
    }
    
    // MARK: - Drawing
    
    @objc func startDrawing() {
        guard let currentDrawingView = cardView.isShowingFront ? frontDrawingView : backDrawingView else {
            return
        }
        if isWriting {
            stopWriting()
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
        currentDrawingView.isUserInteractionEnabled = true
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
        currentDrawingView.isUserInteractionEnabled = false
        addTextTapGesture.isEnabled = true
        for view in dragableViews {
            view.isUserInteractionEnabled = true
        }
        
        titleLabel.isHidden = false
        
        UIView.setAnimationsEnabled(false)
        topLeftButton.setTitle(preferredLeftButtonTitle, for: .normal)
//        topLeftButton.setImage(UIImage(named: "close button"), for: .normal)
        topLeftButton.layoutIfNeeded()
        
        topRightButton.setTitle(preferredRightButtonTitle, for: .normal)
        topRightButton.isEnabled = canSaveDraft || canSaveCard
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
