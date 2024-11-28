FROM python:3.10.12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    NVIDIA_DRIVER_CAPABILITIES=all \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

# Setup system packages
COPY builder/setup.sh /setup.sh
RUN /bin/bash /setup.sh && \
    rm /setup.sh

COPY builder/requirements.txt /requirements.txt 
RUN pip install -r /requirements.txt && \
    rm /requirements.txt

# Install ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /ComfyUI

RUN pip install -r requirements.txt && pip cache purge

# Clone custom Nodes
RUN git -C ./custom_nodes clone --depth 1 https://github.com/storyicon/comfyui_segment_anything
RUN git -C ./custom_nodes clone --depth 1 https://github.com/Fannovel16/comfyui_controlnet_aux
RUN git -C ./custom_nodes clone --depth 1 https://github.com/chflame163/ComfyUI_CatVTON_Wrapper
#we need to install the requirements of the catVTON wrapper
RUN pip install -r ./custom_nodes/ComfyUI_CatVTON_Wrapper/requirements.txt


# Download models
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/DensePose/Base-DensePose-RCNN-FPN.yaml' -d './models/CatVTON/DensePose' -o 'Base-DensePose-RCNN-FPN.yaml'
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/DensePose/densepose_rcnn_R_50_FPN_s1x.yaml' -d './models/CatVTON/DensePose' -o 'densepose_rcnn_R_50_FPN_s1x.yaml'
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/DensePose/model_final_162be9.pkl' -d './models/CatVTON/DensePose' -o 'model_final_162be9.pkl'

RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/SCHP/exp-schp-201908261155-lip.pth' -d './models/CatVTON/SCHP' -o 'exp-schp-201908261155-lip.pth'
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/SCHP/exp-schp-201908301523-atr.pth' -d './models/CatVTON/SCHP' -o 'exp-schp-201908301523-atr.pth'

RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/dresscode-16k-512/attention/model.safetensors' -d './models/CatVTON/dresscode-16k-512/attention' -o 'model.safetensors'

RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/mix-48k-1024/attention/model.safetensors' -d './models/CatVTON/mix-48k-1024/attention' -o 'model.safetensors'

RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/sd-vae-ft-mse/config.json' -d './models/CatVTON/sd-vae-ft-mse' -o 'config.json'
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/sd-vae-ft-mse/diffusion_pytorch_model.safetensors' -d './models/CatVTON/sd-vae-ft-mse' -o 'diffusion_pytorch_model.safetensors'

RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/stable-diffusion-inpainting/scheduler/scheduler_config.json' -d './models/CatVTON/stable-diffusion-inpainting/scheduler' -o 'scheduler_config.json'
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/stable-diffusion-inpainting/unet/config.json' -d './models/CatVTON/stable-diffusion-inpainting/unet' -o 'config.json'
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/stable-diffusion-inpainting/unet/diffusion_pytorch_model.safetensors' -d './models/CatVTON/stable-diffusion-inpainting/unet' -o 'diffusion_pytorch_model.safetensors'

RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/risunobushi/catvton_model_lib/resolve/main/vitonhd-16k-512/attention/model.safetensors' -d './models/CatVTON/vitonhd-16k-512/attention' -o 'model.safetensors'

# Sam
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/lkeab/hq-sam/resolve/main/sam_hq_vit_h.pth' -d './models/sams' -o 'sam_hq_vit_h.pth'

# Grounding Dino
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/GroundingDINO_SwinB.cfg.py' -d './models/grounding-dino' -o 'GroundingDINO_SwinB.cfg.py'
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/groundingdino_swinb_cogcoor.pth' -d './models/grounding-dino' -o 'groundingdino_swinb_cogcoor.pth'

# Densepose
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M 'https://huggingface.co/LayerNorm/DensePose-TorchScript-with-hint-image/resolve/main/densepose_r50_fpn_dl.torchscript' -d './custom_nodes/comfyui_controlnet_aux/ckpts/LayerNorm/DensePose-TorchScript-with-hint-image' -o 'densepose_r50_fpn_dl.torchscript'

# Custom nodes requirements
COPY --chmod=755 src/* ./
RUN ./install_custom_node_dependencies.sh
RUN pip install huggingface_hub==0.25.2 matplotlib


CMD /ComfyUI/start.sh