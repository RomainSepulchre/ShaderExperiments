using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.Controls;

public class FreeCamera : MonoBehaviour {
	public bool enableInputCapture = true;
	public bool holdRightMouseCapture = false;

	public float lookSpeed = 1.5f;
	public float moveSpeed = 10f;
	public float sprintSpeed = 20f;

	bool	m_inputCaptured;
	float	m_yaw;
	float	m_pitch;
	
	void Awake() {
		enabled = enableInputCapture;
	}

	void OnValidate() {
		if(Application.isPlaying)
			enabled = enableInputCapture;
	}

	void CaptureInput() {
		Cursor.lockState = CursorLockMode.Locked;

		Cursor.visible = false;
		m_inputCaptured = true;

		m_yaw = transform.eulerAngles.y;
		m_pitch = transform.eulerAngles.x;
	}

	void ReleaseInput() {
		Cursor.lockState = CursorLockMode.None;
		Cursor.visible = true;
		m_inputCaptured = false;
	}

	void OnApplicationFocus(bool focus) {
		if(m_inputCaptured && !focus)
			ReleaseInput();
	}

	void Update() {
		if(!m_inputCaptured) {
			if(!holdRightMouseCapture && Mouse.current.leftButton.wasPressedThisFrame)
				CaptureInput();
			else if(holdRightMouseCapture && Mouse.current.rightButton.wasPressedThisFrame)
				CaptureInput();
		}

		if(!m_inputCaptured)
			return;

		if(m_inputCaptured) {
			if(!holdRightMouseCapture && Keyboard.current.escapeKey.wasPressedThisFrame)
				ReleaseInput();
			else if(holdRightMouseCapture && Mouse.current.rightButton.wasReleasedThisFrame)
				ReleaseInput();
		}
		
		// Mouse delta divided by 10 to lower default look speed
		var rotStrafe = Mouse.current.delta.ReadValue().x / 10; 
		var rotFwd = Mouse.current.delta.ReadValue().y / 10;

		m_yaw = (m_yaw + lookSpeed * rotStrafe) % 360f;
		m_pitch = (m_pitch - lookSpeed * rotFwd) % 360f;
		transform.rotation = Quaternion.AngleAxis(m_yaw, Vector3.up) * Quaternion.AngleAxis(m_pitch, Vector3.right);

		var speed = Time.deltaTime * (Keyboard.current.leftShiftKey.isPressed ? sprintSpeed : moveSpeed);
		
		float verticalAxis = (Keyboard.current.wKey.isPressed ? 1f : 0f) - (Keyboard.current.sKey.isPressed ? 1f : 0f);
		float horizontalAxis = (Keyboard.current.dKey.isPressed ? 1f : 0f) - (Keyboard.current.aKey.isPressed ? 1f : 0f);
		var forward = speed * verticalAxis;
		var right = speed * horizontalAxis;
		var up = speed * ((Keyboard.current.eKey.isPressed ? 1f : 0f) - (Keyboard.current.qKey.isPressed ? 1f : 0f));
		transform.position += transform.forward * forward + transform.right * right + Vector3.up * up;
	}
}
