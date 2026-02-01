namespace ManejoPresupuestos.Models
{
    public class CrearRecetaViewModel
    {
        public int RecetaId { get; set; }
        public string Nombre { get; set; }

        // Legacy (lo dejamos para no romper cosas viejas)
        public string Tiempo { get; set; }

        // Nuevos campos
        public int TiempoImpresionMin { get; set; }
        public int TiempoPostMin { get; set; }

        public int ProductoId { get; set; }
        public List<CrearRecetaInventarioViewModel> Inventarios { get; set; } = new();
    }

    public class CrearRecetaInventarioViewModel
    {
        public int InventarioId { get; set; }
        public double Cantidad { get; set; }
    }
}