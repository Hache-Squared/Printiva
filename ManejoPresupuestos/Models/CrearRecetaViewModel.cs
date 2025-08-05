namespace ManejoPresupuestos.Models
{
    public class CrearRecetaViewModel
    {
        public string Nombre { get; set; }
        public string Tiempo { get; set; }
        public int ProductoId { get; set; }
        public List<CrearRecetaInventarioViewModel> Inventarios { get; set; }
    }

    public class CrearRecetaInventarioViewModel
    {
        public int InventarioId { get; set; }
        public double Cantidad { get; set; }

    }
}
