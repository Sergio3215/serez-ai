# serez-ai

Neural network library for [Serez-Code](https://serezcode.org), written in pure `.sz` on top of
the core's `Tensor` + `Autodiff`. Keras-style API: build a `Sequential` model, `fit` it, `predict`
— with dense, convolutional, recurrent and transformer layers.

```sz
import "serez-ai"

Random.seed(42)

let X = Tensor.from([[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]])
let y = Tensor.from([[0.0], [1.0], [1.0], [0.0]])

let model = new Sequential()
model.add(new Dense(2, 4, "relu"))
model.add(new Dense(4, 1, "sigmoid"))

let history = model.fit(X, y, new MSE(), 3000, 1.0, true)   // XOR learned

let preds = model.predict(X)
```

## Install

```powershell
sz install serez-ai
```

Then `import "serez-ai"` just works.

## What's inside

- **Layers** — `Dense`, `Conv2D`, `MaxPool2D`, `Flatten`, `Embedding`, `LSTM`, `GRU`,
  `MultiHeadAttention`, `LayerNorm`, `TransformerBlock`.
- **Losses** — `MSE`, `BCE` (numerically stable).
- **Optimizers** — `Adam`, `Momentum`, `SGD` — plug any of them in with `model.fit_opt(...)`,
  or drive a manual loop with `Autodiff.tape()` / `Autodiff.backward()` + `opt.step_layer(layer)`.
- **Training** — `model.fit(X, y, loss, epochs, lr, verbose)` (plain SGD),
  `fit_opt(..., optimizer, ...)`, `fit_dl(X_arr, y_arr, ...)` (shuffled mini-batches via
  `DataLoader`), and `predict(X)`.
- **Transfer learning** — `model.save("base.szai")` / `load(...)` +
  `freeze()` / `unfreeze()` to reuse a trained base and train only a new head.

> **Gotcha (pass-by-value):** in a manual loop, `opt.step_layer(layer)` *returns* the updated
> layer — always assign it back (`model.layers[j] = opt.step_layer(model.layers[j])`); mutations
> inside the call do not propagate to the caller.

## Documentation

The full reference lives on the Serez-Code site:

- **[serez-ai reference](https://serezcode.org/docs/serez-ai)** — every layer, loss, optimizer
  and training method, with input/output shapes and examples.
- **[Build a neural network](https://serezcode.org/guides/neural-network)** — step-by-step
  tutorial, from tensors to a trained model.
- **[Serve a model as an API](https://serezcode.org/guides/serve-model)** — train with serez-ai,
  serve predictions over HTTP with serez-http.

## Examples in the repo

| File | Description |
|---|---|
| `apps/xor_demo.sz` | 2-layer MLP, XOR problem, SGD |
| `apps/mnist_demo.sz` | CNN (Conv2D + MaxPool2D + Flatten + Dense), synthetic 8×8 images |
| `apps/sentiment_demo.sz` | Embedding + LSTM/GRU, binary sentiment classification |
| `apps/transformer_demo.sz` | Embedding + TransformerBlock + Dense, sequence classification |
| `apps/transfer_demo.sz` | Save/load + freeze + fine-tune a head on a new task |

## Requirements

Pure `.sz`, no external dependencies — it uses the core's native `Autodiff`, `Tensor`, `Random`,
`Math` and `File` namespaces (`File` only for `save`/`load`).
