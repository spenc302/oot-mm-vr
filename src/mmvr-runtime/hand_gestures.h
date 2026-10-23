#pragma once
#include "input.h"
#include <openxr/openxr.h>

namespace mmvr {
struct HandGesturePad {
    uint16_t buttons = 0;
    int8_t x = 0, y = 0;
    float grips[2]{}, triggers[2]{};
    bool active = false;
};

class HandGestureInput {
    bool pinching[2][2]{};
    bool fists[2]{};
    bool hasNeutral = false;
    XrVector3f neutral{};
    uint64_t epoch = 0;

    static float Distance(const XrVector3f& a, const XrVector3f& b) {
        const float x = a.x - b.x, y = a.y - b.y, z = a.z - b.z;
        return std::sqrt(x * x + y * y + z * z);
    }

    static bool Pinch(const XrHandJointLocationEXT* joints, int finger, bool held) {
        const auto& thumb = joints[XR_HAND_JOINT_THUMB_TIP_EXT].pose.position;
        const auto& tip = joints[finger].pose.position;
        const float distance = Distance(thumb, tip);
        return distance < (held ? .04f : .027f);
    }

    static bool Fist(const XrHandJointLocationEXT* joints, bool held) {
        const auto& palm = joints[XR_HAND_JOINT_PALM_EXT].pose.position;
        unsigned curled = 0;
        for (const int tip : { XR_HAND_JOINT_INDEX_TIP_EXT, XR_HAND_JOINT_MIDDLE_TIP_EXT,
                               XR_HAND_JOINT_RING_TIP_EXT, XR_HAND_JOINT_LITTLE_TIP_EXT }) {
            curled += Distance(palm, joints[tip].pose.position) < (held ? .105f : .085f);
        }
        return curled >= 3;
    }

  public:
    void Reset() {
        pinching[0][0] = pinching[0][1] = pinching[1][0] = pinching[1][1] = false;
        fists[0] = fists[1] = false;
        hasNeutral = false;
    }

    HandGesturePad Update(const XrHandJointLocationEXT (&joints)[2][XR_HAND_JOINT_COUNT_EXT],
                          const bool (&tracked)[2], uint64_t trackingEpoch) {
        if (epoch != trackingEpoch) {
            Reset();
            epoch = trackingEpoch;
        }

        HandGesturePad result{};
        result.active = tracked[0] || tracked[1];
        if (!result.active) {
            Reset();
            return result;
        }

        for (int hand = 0; hand < 2; ++hand) {
            if (!tracked[hand]) {
                pinching[hand][0] = pinching[hand][1] = fists[hand] = false;
                continue;
            }
            pinching[hand][0] = Pinch(joints[hand], XR_HAND_JOINT_INDEX_TIP_EXT, pinching[hand][0]);
            pinching[hand][1] = Pinch(joints[hand], XR_HAND_JOINT_MIDDLE_TIP_EXT, pinching[hand][1]);
            fists[hand] = Fist(joints[hand], fists[hand]);
        }

        if (tracked[0]) {
            const auto& wrist = joints[0][XR_HAND_JOINT_WRIST_EXT].pose.position;
            if (!hasNeutral) {
                neutral = wrist;
                hasNeutral = true;
            }
            result.x = Axis((wrist.x - neutral.x) / .22f, 0);
            result.y = Axis((wrist.y - neutral.y) / .22f, 0);
            if (pinching[0][0]) result.buttons |= 0x2000; // Z
            if (fists[0]) result.buttons |= 0x0020; // L
            result.grips[0] = fists[0] ? 1.f : 0.f;
            result.triggers[0] = pinching[0][0] ? 1.f : 0.f;
        } else {
            hasNeutral = false;
        }
        if (tracked[1]) {
            if (pinching[1][0]) result.buttons |= 0x8000; // A
            if (pinching[1][1]) result.buttons |= 0x0004; // C-down
            if (fists[1]) result.buttons |= 0x4000; // B
            result.grips[1] = fists[1] ? 1.f : 0.f;
            result.triggers[1] = pinching[1][0] ? 1.f : 0.f;
        }
        return result;
    }
};
} // namespace mmvr
