import SwiftUI
import UIKit

/// Configures the parent navigation bar with UIKit-native bar button items,
/// giving them the native iOS 26 liquid glass appearance.
/// The cancel button uses a plain xmark icon, and the save button uses
/// a checkmark with .done style for prominent blue-tinted glass treatment.
struct GlassNavigationButtons: UIViewControllerRepresentable {
    let onCancel: () -> Void
    let onSave: () -> Void
    var isSaveDisabled: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator(onCancel: onCancel, onSave: onSave)
    }

    func makeUIViewController(context: Context) -> GlassButtonsController {
        let controller = GlassButtonsController()
        controller.coordinator = context.coordinator
        controller.isSaveDisabled = isSaveDisabled
        return controller
    }

    func updateUIViewController(_ controller: GlassButtonsController, context: Context) {
        context.coordinator.onCancel = onCancel
        context.coordinator.onSave = onSave
        controller.coordinator = context.coordinator
        controller.isSaveDisabled = isSaveDisabled
        controller.updateButtons()
    }

    class Coordinator: NSObject {
        var onCancel: () -> Void
        var onSave: () -> Void

        init(onCancel: @escaping () -> Void, onSave: @escaping () -> Void) {
            self.onCancel = onCancel
            self.onSave = onSave
        }

        @objc func cancelTapped() { onCancel() }
        @objc func saveTapped() { onSave() }
    }
}

class GlassButtonsController: UIViewController {
    var coordinator: GlassNavigationButtons.Coordinator?
    var isSaveDisabled = false
    private weak var saveItem: UIBarButtonItem?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupButtons()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        setupButtons()
    }

    func updateButtons() {
        saveItem?.isEnabled = !isSaveDisabled
    }

    func setupButtons() {
        guard let coordinator = coordinator else { return }

        // Walk up the parent chain to find the hosting view controller
        // whose navigationItem is displayed in the navigation bar
        var target: UIViewController? = self
        while let parent = target?.parent {
            if parent is UINavigationController {
                break
            }
            target = parent
        }
        guard let hostVC = target else { return }

        // Cancel button — plain style xmark icon
        let cancelItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: coordinator,
            action: #selector(GlassNavigationButtons.Coordinator.cancelTapped)
        )

        // Save button — .done style for prominent blue-tinted glass
        let saveConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        let checkImage = UIImage(systemName: "checkmark", withConfiguration: saveConfig)

        let save = UIBarButtonItem(
            image: checkImage,
            style: .done,
            target: coordinator,
            action: #selector(GlassNavigationButtons.Coordinator.saveTapped)
        )
        save.tintColor = .systemBlue
        save.isEnabled = !isSaveDisabled
        self.saveItem = save

        hostVC.navigationItem.leftBarButtonItem = cancelItem
        hostVC.navigationItem.rightBarButtonItem = save
    }
}
