using UnityEngine;

public class Aim : MonoBehaviour
{
    public float offset = 1f;
    public float offsetZ = 1f;

    void Update()
    {
        Vector2 direction = new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));

        transform.localPosition = Vector3.ClampMagnitude(new(Mathf.Sin(Mathf.PI * direction.x / 2), Mathf.Sin(Mathf.PI * direction.y / 2), offsetZ), 1.0f) * offset;

    }
}
