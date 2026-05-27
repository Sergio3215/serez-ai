# serez-ai

Neural network library for [Serez-Code](../Serez-code), written in pure `.sz`. Keras-style API with automatic differentiation, convolutional, recurrent, and transformer layers.

## Setup

```sz
import "serez-ai"
```

Run from the parent directory of `serez-ai/` so the import resolves:

```
sz.exe serez-ai/apps/xor_demo.sz
```

---

## Quick start

```sz
import "serez-ai"

Random.seed(42)

let X = Tensor.from([[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]])
let y = Tensor.from([[0.0], [1.0], [1.0], [0.0]])

let model = new Sequential()
model.add(new Dense(2, 4, "relu"))
model.add(new Dense(4, 1, "sigmoid"))

let history = model.fit(X, y, new MSE(), 3000, 1.0, true)

let preds = model.predict(X)
```

---

## Layers

### Dense

```sz
new Dense(in_features, out_features, activation)
```

Fully connected layer. Weights initialized with He initialization.

| Activation | Value |
|---|---|
| ReLU | `"relu"` |
| Sigmoid | `"sigmoid"` |
| Tanh | `"tanh"` |
| None | `"linear"` |

### Conv2D

```sz
new Conv2D(in_channels, out_channels, kernel_size, stride, activation)
```

2D convolution with autodiff via im2col/col2im. Input shape: `[N, H, W, C_in]`.

```sz
let conv = new Conv2D(1, 32, 3, 1, "relu")
let out = conv.forward(x)   // x: [1, 8, 8, 1]
```

### MaxPool2D

```sz
new MaxPool2D(pool_size, stride)
```

Max pooling with argmax mask tracked through the autodiff tape.

### Flatten

```sz
new Flatten()
```

Reshapes `[N, H, W, C]` → `[N, H*W*C]`. No learnable parameters.

### Embedding

```sz
new Embedding(vocab_size, embed_dim)
```

Maps integer token indices to dense vectors via `Tensor.one_hot()` + matmul.

```sz
let emb = new Embedding(10000, 128)
let x = Tensor.from([[3.0]])   // token index
let vec = emb.forward(x)       // [1, 128]
```

### LSTM

```sz
new LSTM(input_size, hidden_size)
```

Long short-term memory. Processes one token at a time; initializes `h0` and `c0` to zeros on each `forward()` call. Returns `[1, hidden_size]`.

```sz
let lstm = new LSTM(128, 64)
let h = lstm.forward(emb_vec)   // [1, 64]
```

### GRU

```sz
new GRU(input_size, hidden_size)
```

Gated recurrent unit. Same interface as LSTM but lighter (3 gates instead of 4). Returns `[1, hidden_size]`.

### MultiHeadAttention

```sz
new MultiHeadAttention(d_model, n_heads)
```

Self-attention with `n_heads` parallel heads. `d_model` must be divisible by `n_heads`. Input/output shape: `[seq_len, d_model]`.

### LayerNorm

```sz
new LayerNorm(d_model, eps)
```

Layer normalization with learnable `gamma` and `beta`. Normalizes each row independently.

```sz
let ln = new LayerNorm(128, 0.000001)
```

### TransformerBlock

```sz
new TransformerBlock(d_model, n_heads, d_ff)
```

Post-LN transformer block: `MHA → Add+Norm → FFN → Add+Norm`.

```sz
let block = new TransformerBlock(32, 4, 64)
let out = block.forward(x)   // x: [seq_len, 32]
```

---

## Losses

### MSE

```sz
new MSE()
```

Mean squared error: `mean((pred - target)²)`.

### BCE

```sz
new BCE()
```

Binary cross-entropy: `-mean(y·log(p) + (1−y)·log(1−p))`. Numerically stable (clamps `p` to `[1e-7, 1-1e-7]`).

---

## Optimizers

### Adam

```sz
new Adam(lr, beta1, beta2)
// e.g. new Adam(0.001, 0.9, 0.999)
```

### Momentum SGD

```sz
new Momentum(lr, momentum)
// e.g. new Momentum(0.01, 0.9)
```

### SGD (object)

```sz
new SGD(lr)
```

Wraps bare SGD as an optimizer object, compatible with `fit_opt` and `step_layer`.

---

## Sequential model

```sz
let model = new Sequential()
model.add(layer)
```

### Training methods

#### `fit` — SGD, single tensor

```sz
let history = model.fit(X, y, loss_fn, epochs, lr, verbose)
// returns: array of loss values, one per epoch
```

| Param | Type | Description |
|---|---|---|
| `X` | Tensor | Input batch |
| `y` | Tensor | Target batch |
| `loss_fn` | MSE / BCE | Loss instance |
| `epochs` | int | Number of epochs |
| `lr` | decimal | Learning rate |
| `verbose` | bool | Print every 10 epochs |

#### `fit_opt` — any optimizer, single tensor

```sz
let history = model.fit_opt(X, y, loss_fn, epochs, optimizer, verbose)
```

Use when you want Adam or Momentum instead of bare SGD.

```sz
let opt = new Adam(0.001, 0.9, 0.999)
let history = model.fit_opt(X, y, new MSE(), 100, opt, true)
```

#### `fit_dl` — SGD with DataLoader (mini-batches)

```sz
let history = model.fit_dl(X_arr, y_arr, loss_fn, epochs, lr, batch_size, verbose)
```

`X_arr` and `y_arr` are arrays of tensors, one per sample. Shuffles and batches automatically each epoch.

```sz
let history = model.fit_dl(X_arr, y_arr, new MSE(), 50, 0.01, 16, true)
```

### Inference

```sz
let pred = model.predict(X)
```

### Freeze / unfreeze

```sz
model.freeze()    // all layers stop updating
model.unfreeze()  // resume training
```

### Save / load weights

```sz
model.save("model.szai")   // serializes all weights to a text file
model.load("model.szai")   // loads weights into an existing model with the same architecture
```

---

## DataLoader

```sz
let dl = new DataLoader(n_samples, batch_size)
dl.shuffle()                  // Fisher-Yates shuffle (call each epoch)
let batches = dl.batches()    // [[idx, ...], [idx, ...], ...]
let nb = dl.n_batches()
```

Manual training loop with DataLoader:

```sz
let dl = new DataLoader(X_arr.length(), 16)
let opt = new Adam(0.001, 0.9, 0.999)
let epoch = 0
while (epoch < 50) {
    dl.shuffle()
    let batches = dl.batches()
    let bi = 0
    while (bi < batches.length()) {
        let batch = batches[bi]
        let si = 0
        while (si < batch.length()) {
            let idx = batch[si]
            Autodiff.tape()
            let pred = model.forward(X_arr[idx])
            let loss = loss_fn.forward(pred, y_arr[idx])
            Autodiff.backward(loss)
            opt.begin_step()
            let j = 0
            while (j < model.layers.length()) {
                let layer = model.layers[j]
                layer = opt.step_layer(layer)
                model.layers[j] = layer
                j = j + 1
            }
            si = si + 1
        }
        bi = bi + 1
    }
    epoch = epoch + 1
}
```

---

## Transfer learning

```sz
// 1. Train and save a base model
let base = new Sequential()
base.add(new Dense(4, 8, "relu"))
base.add(new Dense(8, 4, "relu"))
// ... train ...
base.save("base.szai")

// 2. Load into a new model, freeze it
let feat = new Sequential()
feat.add(new Dense(4, 8, "relu"))
feat.add(new Dense(8, 4, "relu"))
feat.load("base.szai")
feat.freeze()

// 3. Add and train only a new head
let head = new Sequential()
head.add(new Dense(4, 1, "sigmoid"))
// ... train head only ...
```

---

## Manual training loop

For full control (custom architectures, per-layer optimizers, etc.):

```sz
let opt = new Adam(0.001, 0.9, 0.999)

Autodiff.tape()
let pred = model.forward(X)
let loss = loss_fn.forward(pred, y)
Autodiff.backward(loss)

opt.begin_step()
let j = 0
while (j < model.layers.length()) {
    let layer = model.layers[j]
    layer = opt.step_layer(layer)   // must assign back — Serez-Code passes by value
    model.layers[j] = layer
    j = j + 1
}
```

> **Important:** `opt.step_layer(layer)` returns the updated layer. Always assign back with `layer = opt.step_layer(layer)` — mutations inside the call do not propagate to the caller.

---

## Examples

| File | Description |
|---|---|
| `apps/xor_demo.sz` | 2-layer MLP, XOR problem, SGD |
| `apps/mnist_demo.sz` | CNN (Conv2D + MaxPool2D + Flatten + Dense), synthetic 8×8 images |
| `apps/sentiment_demo.sz` | Embedding + LSTM/GRU, binary sentiment classification |
| `apps/transformer_demo.sz` | Embedding + TransformerBlock + Dense, sequence classification |
| `apps/transfer_demo.sz` | Save/load + freeze + fine-tune head on a new task |

---

## Serez-Code requirements

serez-ai requires the following native namespaces from the Serez-Code core:

- `Autodiff` — reverse-mode automatic differentiation tape
- `Tensor` — n-dimensional array with tracked operations
- `Random` — `Random.seed()`, `Random.normalTensor()`, `Random.shuffle()`
- `Math` — `Math.sqrt()`, `Math.pow()`, `Math.round()`
- `File` — `File.read()`, `File.write()` (for save/load)
