export function formToOptions(form) {
  const fd = new FormData(form);
  const opts = {};

  opts.UseRobustScale = fd.get('UseRobustScale') === 'on';
  opts.CenterFrom = fd.get('CenterFrom');
  opts.ScaleFrom = fd.get('ScaleFrom');
  opts.RegularizationMode = fd.get('RegularizationMode');
  opts.TikhonovEpsilon = Number(fd.get('TikhonovEpsilon'));
  opts.AbsoluteEpsilon = Number(fd.get('AbsoluteEpsilon'));
  opts.ApplyPostLowpass = fd.get('ApplyPostLowpass') === 'on';
  opts.LowpassCutoff = Number(fd.get('LowpassCutoff'));
  opts.YLineSpacingSD = Number(fd.get('YLineSpacingSD'));
  console.log(opts);
  return opts;
}

export function applyInitialParams(p) {
  const q = (sel) => document.querySelector(sel);

  if (p.UseRobustScale != null) q('input[name="UseRobustScale"]').checked = !!p.UseRobustScale;
  if (p.CenterFrom) q('select[name="CenterFrom"]').value = p.CenterFrom;
  if (p.ScaleFrom) q('select[name="ScaleFrom"]').value = p.ScaleFrom;
  if (p.RegularizationMode) q('select[name="RegularizationMode"]').value = p.RegularizationMode;
  if (p.TikhonovEpsilon != null) q('input[name="TikhonovEpsilon"]').value = Number(p.TikhonovEpsilon);
  if (p.AbsoluteEpsilon != null) q('input[name="AbsoluteEpsilon"]').value = Number(p.AbsoluteEpsilon);
  if (p.ApplyPostLowpass != null) q('input[name="ApplyPostLowpass"]').checked = !!p.ApplyPostLowpass;
  if (p.LowpassCutoff != null) q('input[name="LowpassCutoff"]').value = Number(p.LowpassCutoff);
  if (p.YLineSpacingSD != null) q('input[name="YLineSpacingSD"]').value = Number(p.YLineSpacingSD);
}
