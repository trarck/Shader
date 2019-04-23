using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class Stage : MonoBehaviour
{
    Vector3 m_MouseStartPosition;
    Vector3 m_ObjectStartRotation;
    bool m_IsTouchDown;

    Transform m_Transform;
    // Start is called before the first frame update
    void Awake()
    {
        m_Transform = transform;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            if (m_Transform != null)
            {
                m_IsTouchDown = true;
                m_MouseStartPosition = Input.mousePosition;
                m_ObjectStartRotation = m_Transform.localEulerAngles;
            }
        }
        else if (Input.GetMouseButtonUp(0))
        {
            m_IsTouchDown = false;
        }

        if (m_IsTouchDown)
        {
            Vector3 delta = Input.mousePosition - m_MouseStartPosition;
            delta.z = delta.y;
            delta.y = delta.x;
            delta.x = delta.z;
            delta.z = 0;
            
            m_Transform.localEulerAngles = m_ObjectStartRotation - delta;
        }
    }

}
