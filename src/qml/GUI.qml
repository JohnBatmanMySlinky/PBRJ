import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.0
import org.julialang 1.0
import "content"  // for NamedSlider

ApplicationWindow {
	visible: true
	width: 640
	height: 480
	title: qsTr("Julia Canvas")

	ColumnLayout {
		anchors.fill: parent

		RowLayout {
			Label {text: "Look At"; font.pixelSize: 32}
			Label {text: "X"; font.pixelSize: 16}
			SpinBox {
				id: la_x
				from: -1000; to: 1000; value: 300
				editable: true
			}
			Label {text: "Y"; font.pixelSize: 16}
			SpinBox {
				id: la_y
				from: -1000; to: 1000; value: -200
				editable: true
			}
			Label {text: "Z"; font.pixelSize: 16}
			SpinBox {
				id: la_z
				from: -1000; to: 1000; value: 0
				editable: true
			}
		}
		RowLayout {
			Label {text: "Look From"; font.pixelSize: 32}
			Label {text: "X"; font.pixelSize: 16}
			SpinBox {
				id: lf_x
				from: -1000; to: 1000; value: 800
				editable: true
			}
			Label {text: "Y"; font.pixelSize: 16}
			SpinBox {
				id: lf_y
				from: -1000; to: 1000; value: 500
				editable: true
			}
			Label {text: "Z"; font.pixelSize: 16}
			SpinBox {
				id: lf_z
				from: -1000; to: 1000; value: 800
				editable: true
			}
		}
		Button {
			text: "Ok"
			onClicked: Julia.test_display(jdisp, la_x.value, la_y.value, la_z.value, lf_x.value, lf_y.value, lf_z.value)
		}
		
		JuliaDisplay {
			id: jdisp
			width: 512
			height: 512
		}
	}
}

