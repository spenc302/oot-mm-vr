#pragma once
#ifdef __ANDROID__
#include "first_person.h"
#include "gles_bridge.h"
#include <array>
#include <vector>
namespace mmvr {
class HandRendererGLES {
    struct Vertex {
        float x, y, z;
    };
    EGLContext owner = EGL_NO_CONTEXT;
    GLuint program = 0, vao = 0, vbo = 0;
    GLint colorUniform = -1;

    static GLuint Compile(GLenum type, const char* source) {
        GLuint shader = glCreateShader(type);
        glShaderSource(shader, 1, &source, nullptr);
        glCompileShader(shader);
        GLint success = GL_FALSE;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if (!success) {
            glDeleteShader(shader);
            throw std::runtime_error("Tracked-hand GLES shader compilation failed");
        }
        return shader;
    }

    void Initialize() {
        constexpr char vertexSource[] =
            "#version 300 es\nlayout(location=0) in vec3 position;\n"
            "void main(){gl_Position=vec4(position,1.0);}\n";
        constexpr char fragmentSource[] =
            "#version 300 es\nprecision mediump float;\nuniform vec4 handColor;\n"
            "out vec4 outputColor;\nvoid main(){outputColor=handColor;}\n";
        const GLuint vertex = Compile(GL_VERTEX_SHADER, vertexSource);
        const GLuint fragment = Compile(GL_FRAGMENT_SHADER, fragmentSource);
        program = glCreateProgram();
        glAttachShader(program, vertex);
        glAttachShader(program, fragment);
        glLinkProgram(program);
        glDeleteShader(vertex);
        glDeleteShader(fragment);
        GLint success = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &success);
        if (!success) {
            glDeleteProgram(program);
            program = 0;
            throw std::runtime_error("Tracked-hand GLES shader link failed");
        }
        colorUniform = glGetUniformLocation(program, "handColor");
        glGenVertexArrays(1, &vao);
        glGenBuffers(1, &vbo);
    }

    static XrVector3f ToEye(const XrVector3f& point, const XrPosef& view) {
        XrVector3f value{ point.x - view.position.x, point.y - view.position.y, point.z - view.position.z };
        const auto& q = view.orientation;
        const float x = -q.x, y = -q.y, z = -q.z;
        const float tx = 2.f * (y * value.z - z * value.y);
        const float ty = 2.f * (z * value.x - x * value.z);
        const float tz = 2.f * (x * value.y - y * value.x);
        return { value.x + q.w * tx + (y * tz - z * ty),
                 value.y + q.w * ty + (z * tx - x * tz),
                 value.z + q.w * tz + (x * ty - y * tx) };
    }

    static bool Project(const XrVector3f& point, const XrView& view, Vertex& result) {
        const XrVector3f eye = ToEye(point, view.pose);
        if (!std::isfinite(eye.x) || !std::isfinite(eye.y) || !std::isfinite(eye.z) ||
            eye.z >= -.035f || eye.z < -30.f)
            return false;
        const float left = std::tan(view.fov.angleLeft), right = std::tan(view.fov.angleRight);
        const float down = std::tan(view.fov.angleDown), up = std::tan(view.fov.angleUp);
        const float inverseDepth = -1.f / eye.z;
        const float x = eye.x * inverseDepth, y = eye.y * inverseDepth;
        const float nearPlane = .035f, farPlane = 30.f;
        result = {
            2.f * (x - left) / (right - left) - 1.f,
            2.f * (y - down) / (up - down) - 1.f,
            (farPlane + nearPlane) / (farPlane - nearPlane) -
                2.f * farPlane * nearPlane * inverseDepth / (farPlane - nearPlane)
        };
        return std::isfinite(result.x) && std::isfinite(result.y) && std::isfinite(result.z);
    }

    static void AddSegment(std::vector<Vertex>& vertices, const TrackingFrame& frame, int hand, int a, int b,
                          const XrView& view) {
        if (!frame.handJointValid[hand][a] || !frame.handJointValid[hand][b])
            return;
        Vertex first{}, second{};
        if (Project(frame.handJoints[hand][a].position, view, first) &&
            Project(frame.handJoints[hand][b].position, view, second)) {
            vertices.push_back(first);
            vertices.push_back(second);
        }
    }

    static void AddPalm(std::vector<Vertex>& vertices, const TrackingFrame& frame, int hand, const XrView& view) {
        constexpr int fan[] = {
            XR_HAND_JOINT_WRIST_EXT, XR_HAND_JOINT_INDEX_METACARPAL_EXT, XR_HAND_JOINT_MIDDLE_METACARPAL_EXT,
            XR_HAND_JOINT_WRIST_EXT, XR_HAND_JOINT_MIDDLE_METACARPAL_EXT, XR_HAND_JOINT_RING_METACARPAL_EXT,
            XR_HAND_JOINT_WRIST_EXT, XR_HAND_JOINT_RING_METACARPAL_EXT, XR_HAND_JOINT_LITTLE_METACARPAL_EXT,
            XR_HAND_JOINT_PALM_EXT, XR_HAND_JOINT_THUMB_METACARPAL_EXT, XR_HAND_JOINT_INDEX_METACARPAL_EXT,
        };
        for (size_t i = 0; i < std::size(fan); i += 3) {
            if (!frame.handJointValid[hand][fan[i]] || !frame.handJointValid[hand][fan[i + 1]] ||
                !frame.handJointValid[hand][fan[i + 2]])
                continue;
            Vertex triangle[3]{};
            bool valid = true;
            for (int j = 0; j < 3; ++j)
                valid &= Project(frame.handJoints[hand][fan[i + j]].position, view, triangle[j]);
            if (valid)
                vertices.insert(vertices.end(), std::begin(triangle), std::end(triangle));
        }
    }

  public:
    void Draw(const GlImage& target, const XrView& view, const TrackingFrame& frame) {
        if (eglGetCurrentContext() == EGL_NO_CONTEXT || !target.framebuffer || !target.width || !target.height)
            return;
        bool visible = false;
        for (bool valid : frame.handSkeletonValid)
            visible |= valid;
        if (!visible)
            return;

        const EGLContext current = eglGetCurrentContext();
        if (owner != current) {
            owner = current;
            program = vao = vbo = 0;
            colorUniform = -1;
            Initialize();
        }

        GLint oldFramebuffer = 0, oldProgram = 0, oldVao = 0, oldArrayBuffer = 0, oldViewport[4]{};
        GLint oldBlendSrcRgb = 0, oldBlendDstRgb = 0, oldBlendSrcAlpha = 0, oldBlendDstAlpha = 0;
        GLint oldBlendEquationRgb = 0, oldBlendEquationAlpha = 0;
        glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &oldFramebuffer);
        glGetIntegerv(GL_CURRENT_PROGRAM, &oldProgram);
        glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &oldVao);
        glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &oldArrayBuffer);
        glGetIntegerv(GL_VIEWPORT, oldViewport);
        glGetIntegerv(GL_BLEND_SRC_RGB, &oldBlendSrcRgb);
        glGetIntegerv(GL_BLEND_DST_RGB, &oldBlendDstRgb);
        glGetIntegerv(GL_BLEND_SRC_ALPHA, &oldBlendSrcAlpha);
        glGetIntegerv(GL_BLEND_DST_ALPHA, &oldBlendDstAlpha);
        glGetIntegerv(GL_BLEND_EQUATION_RGB, &oldBlendEquationRgb);
        glGetIntegerv(GL_BLEND_EQUATION_ALPHA, &oldBlendEquationAlpha);
        const GLboolean blend = glIsEnabled(GL_BLEND), depth = glIsEnabled(GL_DEPTH_TEST);
        const GLboolean scissor = glIsEnabled(GL_SCISSOR_TEST), cull = glIsEnabled(GL_CULL_FACE);
        GLfloat oldLineWidth = 1;
        glGetFloatv(GL_LINE_WIDTH, &oldLineWidth);

        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, target.framebuffer);
        glViewport(0, 0, target.width, target.height);
        glDisable(GL_DEPTH_TEST);
        glDisable(GL_SCISSOR_TEST);
        glDisable(GL_CULL_FACE);
        glEnable(GL_BLEND);
        glBlendEquation(GL_FUNC_ADD);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glLineWidth(2.5f);
        glUseProgram(program);
        glBindVertexArray(vao);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), nullptr);

        for (int hand = 0; hand < 2; ++hand) {
            if (!frame.handSkeletonValid[hand])
                continue;
            std::vector<Vertex> palm, bones;
            AddPalm(palm, frame, hand, view);
            AddSegment(bones, frame, hand, XR_HAND_JOINT_WRIST_EXT, XR_HAND_JOINT_PALM_EXT, view);
            constexpr int chains[5][5] = {
                { XR_HAND_JOINT_THUMB_METACARPAL_EXT, XR_HAND_JOINT_THUMB_PROXIMAL_EXT,
                  XR_HAND_JOINT_THUMB_DISTAL_EXT, XR_HAND_JOINT_THUMB_TIP_EXT, -1 },
                { XR_HAND_JOINT_INDEX_METACARPAL_EXT, XR_HAND_JOINT_INDEX_PROXIMAL_EXT,
                  XR_HAND_JOINT_INDEX_INTERMEDIATE_EXT, XR_HAND_JOINT_INDEX_DISTAL_EXT, XR_HAND_JOINT_INDEX_TIP_EXT },
                { XR_HAND_JOINT_MIDDLE_METACARPAL_EXT, XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT,
                  XR_HAND_JOINT_MIDDLE_INTERMEDIATE_EXT, XR_HAND_JOINT_MIDDLE_DISTAL_EXT, XR_HAND_JOINT_MIDDLE_TIP_EXT },
                { XR_HAND_JOINT_RING_METACARPAL_EXT, XR_HAND_JOINT_RING_PROXIMAL_EXT,
                  XR_HAND_JOINT_RING_INTERMEDIATE_EXT, XR_HAND_JOINT_RING_DISTAL_EXT, XR_HAND_JOINT_RING_TIP_EXT },
                { XR_HAND_JOINT_LITTLE_METACARPAL_EXT, XR_HAND_JOINT_LITTLE_PROXIMAL_EXT,
                  XR_HAND_JOINT_LITTLE_INTERMEDIATE_EXT, XR_HAND_JOINT_LITTLE_DISTAL_EXT, XR_HAND_JOINT_LITTLE_TIP_EXT },
            };
            for (const auto& chain : chains)
                for (int i = 0; i < 4 && chain[i + 1] >= 0; ++i)
                    AddSegment(bones, frame, hand, chain[i], chain[i + 1], view);

            glUniform4f(colorUniform, .82f, .57f, .39f, .92f);
            glBindBuffer(GL_ARRAY_BUFFER, vbo);
            glBufferData(GL_ARRAY_BUFFER, palm.size() * sizeof(Vertex), palm.data(), GL_STREAM_DRAW);
            glDrawArrays(GL_TRIANGLES, 0, static_cast<GLsizei>(palm.size()));
            glUniform4f(colorUniform, .96f, .78f, .63f, 1.f);
            glBufferData(GL_ARRAY_BUFFER, bones.size() * sizeof(Vertex), bones.data(), GL_STREAM_DRAW);
            glDrawArrays(GL_LINES, 0, static_cast<GLsizei>(bones.size()));
        }

        glBindBuffer(GL_ARRAY_BUFFER, oldArrayBuffer);
        glBindVertexArray(oldVao);
        glUseProgram(oldProgram);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, oldFramebuffer);
        glViewport(oldViewport[0], oldViewport[1], oldViewport[2], oldViewport[3]);
        glBlendEquationSeparate(oldBlendEquationRgb, oldBlendEquationAlpha);
        glBlendFuncSeparate(oldBlendSrcRgb, oldBlendDstRgb, oldBlendSrcAlpha, oldBlendDstAlpha);
        glLineWidth(oldLineWidth);
        if (blend) glEnable(GL_BLEND); else glDisable(GL_BLEND);
        if (depth) glEnable(GL_DEPTH_TEST); else glDisable(GL_DEPTH_TEST);
        if (scissor) glEnable(GL_SCISSOR_TEST); else glDisable(GL_SCISSOR_TEST);
        if (cull) glEnable(GL_CULL_FACE); else glDisable(GL_CULL_FACE);
    }
};
} // namespace mmvr
#endif
