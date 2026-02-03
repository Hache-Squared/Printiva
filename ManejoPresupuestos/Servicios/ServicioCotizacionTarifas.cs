using ManejoPresupuestos.Models;

namespace ManejoPresupuestos.Servicios
{
    public interface IServicioCotizacionTarifas
    {
        Task<CotizacionTarifaPreviewResponseDto> PreviewAsync(int loginId, CotizacionTarifaPreviewRequestDto req);
    }

    public class ServicioCotizacionTarifas : IServicioCotizacionTarifas
    {
        private readonly IRepositorioRecetas repositorioRecetas;
        private readonly IRepositorioTarifas repositorioTarifas;

        public ServicioCotizacionTarifas(
            IRepositorioRecetas repositorioRecetas,
            IRepositorioTarifas repositorioTarifas
        )
        {
            this.repositorioRecetas = repositorioRecetas;
            this.repositorioTarifas = repositorioTarifas;
        }

        private static bool EsConceptoInventarioRelevante(string? codigo)
        {
            if (string.IsNullOrWhiteSpace(codigo)) return false;

            return codigo.Equals("MATERIAL_UNIT", StringComparison.OrdinalIgnoreCase)
                || codigo.Equals("MATERIAL_GENERAL", StringComparison.OrdinalIgnoreCase)
                || codigo.Equals("MATERIAL_GENERAL_INV_GLOBAL", StringComparison.OrdinalIgnoreCase);
        }

        private static bool EsConceptoImpresoraRelevante(string? codigo)
        {
            if (string.IsNullOrWhiteSpace(codigo)) return false;

            return codigo.Equals("MATERIAL_GENERAL", StringComparison.OrdinalIgnoreCase)
                || codigo.Equals("MATERIAL_GENERAL_PRN_GLOBAL", StringComparison.OrdinalIgnoreCase);
        }

        public async Task<CotizacionTarifaPreviewResponseDto> PreviewAsync(int loginId, CotizacionTarifaPreviewRequestDto req)
        {
            var res = new CotizacionTarifaPreviewResponseDto();

            try
            {
                req ??= new CotizacionTarifaPreviewRequestDto();

                // ✅ AHORA: items con producto y cantidad (Modelado o Producción)
                var itemsConProducto = (req.Items ?? new List<CotizacionTarifaPreviewItemDto>())
                    .Where(x => x != null
                             && (x.ConceptoTipoId == 1 || x.ConceptoTipoId == 2)
                             && x.ProductoId > 0
                             && x.Cantidad > 0)
                    .ToList();

                if (itemsConProducto.Count == 0)
                {
                    res.TotalTarifas = 0;
                    res.Result = "success";
                    res.Message = "OK";
                    return res;
                }

                // 1) Map ProductoId -> RecetaId (tomamos la receta "más nueva" por RecetaId)
                var recetas = (await repositorioRecetas.ObtenerTodos(new ParametroObtenerRecetas
                {
                    ElementoObtenerId = 0,
                    LoginId = loginId
                })).ToList();

                var recetaByProducto = recetas
                    .Where(r => r.ProductoId > 0)
                    .GroupBy(r => r.ProductoId)
                    .ToDictionary(
                        g => g.Key,
                        g => g.OrderByDescending(x => x.RecetaId).First().RecetaId
                    );

                // 2) Consumir recetas y acumular consumos por InventarioId
                var consumos = new Dictionary<int, decimal>(); // InventarioId -> cantidad total

                foreach (var it in itemsConProducto)
                {
                    if (!recetaByProducto.TryGetValue(it.ProductoId, out var recetaId) || recetaId <= 0)
                    {
                        res.ProductosSinReceta.Add(!string.IsNullOrWhiteSpace(it.ProductoNombre)
                            ? it.ProductoNombre!
                            : $"ProductoId {it.ProductoId}");
                        continue;
                    }

                    var mats = (await repositorioRecetas.ObtenerRecetaInventarioNecesario(recetaId, loginId)).ToList();

                    foreach (var m in mats)
                    {
                        var baseQty = Convert.ToDecimal(m.CantidadAsignada);
                        var qty = baseQty * it.Cantidad;

                        if (qty <= 0) continue;

                        if (consumos.TryGetValue(m.InventarioId, out var old))
                            consumos[m.InventarioId] = old + qty;
                        else
                            consumos[m.InventarioId] = qty;
                    }
                }

                // 3) Aplicar tarifas por inventario (evitar duplicar globales)
                var detalle = new List<TarifaAplicadaDto>();
                var globalTarifaIdsYaAgregadas = new HashSet<int>();

                foreach (var kv in consumos)
                {
                    var inventarioId = kv.Key;
                    var qtyConsumida = kv.Value;

                    var tarifas = (await repositorioTarifas.ObtenerPorInventario(inventarioId, loginId)).ToList();

                    foreach (var t in tarifas)
                    {
                        if (!EsConceptoInventarioRelevante(t.ConceptoCodigo))
                            continue;

                        if (t.EsGlobal)
                        {
                            if (!globalTarifaIdsYaAgregadas.Add(t.TarifaId))
                                continue;
                        }

                        decimal cantidadAplicada;

                        if (t.ConceptoCodigo.Equals("MATERIAL_UNIT", StringComparison.OrdinalIgnoreCase))
                            cantidadAplicada = qtyConsumida;
                        else
                            cantidadAplicada = 1m;

                        var subtotal = t.Monto * cantidadAplicada;

                        // ✅ AplicaA con nombre de inventario
                        var aplicaA = "GLOBAL";
                        if (!t.EsGlobal)
                        {
                            aplicaA = !string.IsNullOrWhiteSpace(t.InventarioNombre)
                                ? t.InventarioNombre!
                                : $"Inventario #{inventarioId}";
                        }

                        detalle.Add(new TarifaAplicadaDto
                        {
                            TarifaId = t.TarifaId,
                            ConceptoCodigo = t.ConceptoCodigo,
                            ConceptoNombre = t.ConceptoNombre,
                            TarifaNombre = t.TarifaNombre ?? "",
                            Unidad = t.Unidad ?? "",
                            Moneda = t.Moneda ?? "MXN",
                            Monto = t.Monto,
                            Cantidad = cantidadAplicada,
                            Subtotal = subtotal,
                            EsGlobal = t.EsGlobal,
                            AplicaA = aplicaA
                        });
                    }
                }

                // 4) (Opcional) Impresora (si luego lo ocupas)
                if (req.ImpresoraId.HasValue && req.ImpresoraId.Value > 0)
                {
                    var impId = req.ImpresoraId.Value;
                    var tarifasImp = (await repositorioTarifas.ObtenerPorImpresora(impId, loginId)).ToList();

                    foreach (var t in tarifasImp)
                    {
                        if (!EsConceptoImpresoraRelevante(t.ConceptoCodigo))
                            continue;

                        if (t.EsGlobal)
                        {
                            if (!globalTarifaIdsYaAgregadas.Add(t.TarifaId))
                                continue;
                        }

                        var subtotal = t.Monto * 1m;

                        var aplicaA = t.EsGlobal
                            ? "GLOBAL"
                            : (!string.IsNullOrWhiteSpace(t.ImpresoraNombre) ? t.ImpresoraNombre! : $"Impresora #{impId}");

                        detalle.Add(new TarifaAplicadaDto
                        {
                            TarifaId = t.TarifaId,
                            ConceptoCodigo = t.ConceptoCodigo,
                            ConceptoNombre = t.ConceptoNombre,
                            TarifaNombre = t.TarifaNombre ?? "",
                            Unidad = t.Unidad ?? "",
                            Moneda = t.Moneda ?? "MXN",
                            Monto = t.Monto,
                            Cantidad = 1m,
                            Subtotal = subtotal,
                            EsGlobal = t.EsGlobal,
                            AplicaA = aplicaA
                        });
                    }
                }

                res.Detalle = detalle
                    .OrderBy(x => x.EsGlobal)
                    .ThenBy(x => x.ConceptoNombre)
                    .ThenBy(x => x.TarifaNombre)
                    .ToList();

                res.TotalTarifas = res.Detalle.Sum(x => x.Subtotal);
                res.Result = "success";
                res.Message = "OK";
                return res;
            }
            catch (Exception ex)
            {
                res.Result = "fail";
                res.Message = ex.Message;
                return res;
            }
        }
    }
}