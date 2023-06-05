### Overview
- First setup the environment [0]. Then download the weights [1].
- Then pick a strategy for the machine and transform the weights accordingly [2].
- Run the chat module with the transformed weights [3].


## 0 - Dependencies
Needs python 3.10. Had an error on torch with python 3.11.

Then needs python packages of tokenizers, prompt-toolkit and torch.

- https://pypi.org/project/tokenizers/
- https://pypi.org/project/prompt-toolkit/
- https://pytorch.org/get-started/locally/#macos-version


## [wip] 0 - Dependencies With Nix

### x86_64-darwin ~or aarch64-darwin~
- [wip] for aarch64-darwin, need to modify the flake.

### Make sure you have nix package manager setup
Following command will create a read-only drive for nix, where all the dependencies will reside. The official source and more info here: https://nixos.org/download.html#nix-install-macos
`$ sh <(curl -L https://nixos.org/nix/install)`

And the manual for explanation of each step: https://nixos.org/manual/nix/stable/installation/installing-binary.html#macos-installation

Nix works quite different than other package managers, it is very unlikely that packages installed by it will ever be visible to existing software on the system. So other package managers should not get affected. Uninstall requires quite a few steps, including here just in case: https://nixos.org/manual/nix/stable/installation/uninstall.html#macos

### Enable Flake support
 Flakes allow to specify lock files for dependencies, which significantly improves reproducibility. It is still in beta and subject to change, so needs to be enabled specifically. Here is a few way to do it:
 https://nixos.wiki/wiki/Flakes#Permanent

### Clone the repository
Clone the fork to get the source and the flake:

`git clone git@github.com:dogayuksel/ChatRWKV.git`

### Enable flake to install all the dependencies into nix store
Navigate into the directory and run:

`nix develop`

This runs a bash shell that has all the dependencies specified in the flake. They will be installed into the nix store.

If you run `which python` at this point,
You would see something like:
```
bash-5.2$ which python
/nix/store/48309r3j6ivbyqw9qnlyvhbghn4kiv1r-python3-3.10.11/bin/python
```


## 1 - Download the Weights

### Get the weight from huggingface
https://huggingface.co/BlinkDL/rwkv-4-raven/tree/main

This seems to be the latest 6GB model. Did run on a 2018 Macbook Pro's CPU. It is slow, 2 words per minute slow, but it works:
- https://huggingface.co/BlinkDL/rwkv-4-raven/blob/main/RWKV-4-Raven-3B-v12-Eng98%25-Other2%25-20230520-ctx4096.pth

This seems to be the latest 26GB model trained mostly with English material:
- https://huggingface.co/BlinkDL/rwkv-4-raven/blob/main/RWKV-4-Raven-14B-v12-Eng98%25-Other2%25-20230523-ctx8192.pth

Weights are more of an art then it is science at this point. Bigger the size, most likely will display more intelligence. But weights need to be loaded (so fit) into the VRAM or RAM, in oder to get reasonable performance. There are more weights, on BlinkDL's huggingface page, that might be worth exploring.


## 2 - Transform the weights
Weights we downloaded is a matrix of floating point 16s. It can be used as is, if we wanted to run the whole thing with `cuda fp16` strategy. But then we need as much VRAM, as the size of the model.

### Strategies

Another strategy is to use `cuda fp16i8`, this halves the model, at the expense of accuracy. Then we would need half the VRAM.

Another strategy would be to run the whole thing on the cpu, namely `cpu fp32`.

We can also run some layers on the GPU, as much as our VRAM allows and the rest on the CPU. Then our strategy would look something like: `cuda fp16 *20 -> cpu fp32`.

Similarly, we can run the first 20s layer at half precision on the GPU and the rest at full precision. And that strategy would look something like this: `cuda fp16i8 *20 -> cuda fp16`.

Check out the table on the original repository for more details:
https://github.com/BlinkDL/ChatRWKV/blob/main/ChatRWKV-strategy.png


### How to transform
Clone the repository if you haven't already:
`git clone git@github.com:BlinkDL/ChatRWKV.git`

Navigate to `v2` directory, we will use the modules there.

Convert downloaded model using the script `convert_model.py`.
https://github.com/BlinkDL/ChatRWKV/blob/main/v2/convert_model.py

Example below, and more in the module.
```
# python convert_model.py --in '/fsx/BlinkDL/HF-MODEL/rwkv-4-pile-14b/RWKV-4-Pile-14B-20230313-ctx8192-test1050' --out 'fp16i8_RWKV-4-Pile-14B-20230313-ctx8192-test1050' --strategy 'cuda fp16i8'
```

This command requires a lot of RAM, if it is a large model will likely have to rely on the hard drive.


## 3 - Running the chat bot
We will modify and use the modules in `v2` directory.

Each module has two variables that must be changed when we setup initially and whenever we change the model or the strategy.
- Model Name
  - (omit `.pth` extension, uses just the name)
  - (haven't tried with relative paths (!))
- The strategy used for the module

This configuration should be switched on for cuda strategies, and should stay off otherwise.

`os.environ["RWKV_CUDA_ON"] = '0'`

### Running the benchmark against the bot
Once model name (`MODEL_NAME = '/Users/xyz/path-to-model'`) and strategy (`model = RWKV(model=MODEL_NAME, strategy='cpu fp32i8')`) is updated, run the command in `v2` directory:

`python benchmark_more.py`

This will feed some predetermined questions the model and print the output. It is useful to see how different strategies, different model sizes, different parameters affect the output quality.

### Running the chat agent
Once model name (`args.MODEL_NAME = '/User/xyz/path-to-model'`) and strategy is updated (`args.strategy = 'cuda fp16'`), run the command in `v2` directory:

`python chat.py`

This will start a chat session, which has received some instructions. You can modify the instructions in `v2/prompt/default/English-2.py` to initialize the chat session differently.
